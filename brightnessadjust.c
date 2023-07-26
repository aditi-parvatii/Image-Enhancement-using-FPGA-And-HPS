#include <stdio.h>
#include <unistd.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <intelfpgaup/video.h>
#define PI 3.141592654

typedef unsigned char byte;
// The dimensions of the image
int width, height;
int screen_x, screen_y, char_x, char_y;

struct pixel {
    byte b;
    byte g;
    byte r;
};

// Read BMP file and extract the pixel values (store in data) and header (store in header)
// Data is data[0] = BLUE, data[1] = GREEN, data[2] = RED, data[3] = BLUE, etc...
int read_bmp(char *filename, byte **header, struct pixel **data) {
    struct pixel *data_tmp;
    byte *header_tmp;
    FILE *file = fopen (filename, "rb");
    
    if (!file) return -1;
    
    // read the 54-byte header
    header_tmp = malloc (54 * sizeof(byte));
    fread (header_tmp, sizeof(byte), 54, file); 

    // get height and width of image from the header
    width = *(int*)(header_tmp + 18);  // width is a 32-bit int at offset 18
    height = *(int*)(header_tmp + 22); // height is a 32-bit int at offset 22

    // Read in the image
    int size = width * height;
    data_tmp = malloc (size * sizeof(struct pixel)); 
    fread (data_tmp, sizeof(struct pixel), size, file); // read the data
    fclose (file);
    
    *header = header_tmp;
    *data = data_tmp;
    
    return 0;
}

// Adjust the brightness of each pixel in the image
// The brightness value should be between -255 and 255
void brightness_operation(struct pixel **data, int brightness,int sign) {
    int x, y;
    int new_r, new_g, new_b;
    // Declare image as a 2-D array so that we can use the syntax image[row][column]
    struct pixel (*image)[width] = (struct pixel (*)[width])*data;
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            // Adjust the brightness of each channel (r, g, b) separately
            if (sign==1){
            new_r = image[y][x].r + brightness;
            new_g = image[y][x].g + brightness;
            new_b = image[y][x].b + brightness;
            }
	    else{
            new_r = image[y][x].r - brightness;
            new_g = image[y][x].g - brightness;
            new_b = image[y][x].b - brightness;
	    }
            // Ensure the values stay within the valid range of 0-255
            image[y][x].r = (new_r < 0) ? 0 : ((new_r > 255) ? 255 : new_r);
            image[y][x].g = (new_g < 0) ? 0 : ((new_g > 255) ? 255 : new_g);
            image[y][x].b = (new_b < 0) ? 0 : ((new_b > 255) ? 255 : new_b);
        }
    }
}

// Write the grayscale image to disk. The 8-bit grayscale values should be inside the
// r channel of each pixel.
void write_bmp(char *filename, byte *header, struct pixel *data) {
    FILE* file = fopen (filename, "wb");
    // declare image as a 2-D array so that we can use the syntax image[row][column]
    struct pixel (*image)[width] = (struct pixel (*)[width]) data;
    
    // write the 54-byte header
    fwrite (header, sizeof(byte), 54, file); 
    int y, x;
    
    // the r field of the pixel has the grayscale value; copy to g and b.
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            image[y][x].r = image[y][x].r;
            image[y][x].b = image[y][x].b;
            image[y][x].g = image[y][x].g;
        }
    }
    int size = width * height;
    fwrite (image, sizeof(struct pixel), size, file); // write the data
    fclose (file);
}
void draw_image (struct pixel  * data)
{
    int x, y, stride_x, stride_y, i, j, vga_x, vga_y;
    int r, g, b, color;
    struct pixel (*image)[width] = (struct pixel (*)[width]) data; // allow image[][]

    video_clear ( );
    // scale the image to fit the screen
    stride_x = (width > screen_x) ? width / screen_x : 1;
    stride_y = (height > screen_y) ? height / screen_y : 1;
    // scale proportionally (don't stretch the image)
    stride_y = (stride_x > stride_y) ? stride_x : stride_y;
    stride_x = (stride_y > stride_x) ? stride_y : stride_x;
    for (y = 0; y < height; y += stride_y) {
        for (x = 0; x < width; x += stride_x) {
            // find the average of the pixels being scaled down to the VGA resolution
            r = 0; g = 0; b = 0;
            for (i = 0; i < stride_y; i++) {
                for (j = 0; j < stride_x; ++j) {
                    r += image[y + i][x + j].r;
                    g += image[y + i][x + j].g;
                    b += image[y + i][x + j].b;
                }
            }
            r = r / (stride_x * stride_y);
            g = g / (stride_x * stride_y);
            b = b / (stride_x * stride_y);

            // now write the pixel color to the VGA display
            r = r >> 3;      // VGA has 5 bits of red
            g = g >> 2;      // VGA has 6 bits of green
            b = b >> 3;      // VGA has 5 bits of blue
            color = r << 11 | g << 5 | b;
            vga_x = x / stride_x;
            vga_y = y / stride_y;
            if (screen_x > width / stride_x)   // center if needed
                video_pixel (vga_x + (screen_x-(width/stride_x))/2, (screen_y-1) - vga_y, color); 
            else
                if ((vga_x < screen_x) && (vga_y < screen_y))
                    video_pixel (vga_x, (screen_y-1) - vga_y, color); 
        }
    }
    video_show ( );
}

int main(int argc, char *argv[]) {
    struct pixel *image;
    //signed int *G_x, *G_y;
    byte *header;
    int debug = 0, video = 0;
    time_t start, end;
    
    // Check inputs
    if (argc < 2) {
        printf("Usage: part1 [-d] [-v] <BMP filename>\n");
        printf("-d: produces debug output for each stage\n");
        printf("-v: draws the input and output images on a video-out display\n");
        return 0;
    }
    int opt;
    while ((opt = getopt (argc, argv, "dv")) != -1) {
        switch (opt) {
            case 'd':  
                debug = 1;
                break;  
            case 'v':  
                video = 1;
                break;  
            case '?':  
                printf("unknown option: %c\n", optopt); 
                break;  
        }  
    }  
    // Open input image file (24-bit bitmap image)
    if (read_bmp (argv[optind], &header, &image) < 0) {
        printf("Failed to read BMP\n");
        return 0;
    }
    if (video) {
        if (!video_open ())
        {
            printf ("Error: could not open video device\n");
            return -1;
        }
        video_read (&screen_x, &screen_y, &char_x, &char_y);   // get VGA screen size
        draw_image (image);
    }

    /********************************************
    *          IMAGE PROCESSING STAGES          *
    ********************************************/
    
    // Start measuring time
    start = clock ();
    
    ///brightness operation
    brightness_operation (&image, 100, 0);
    if (debug) write_bmp ("brightness_operation.bmp", header, image);
    
    
    
    
    end = clock();
    
    printf("TIME ELAPSED: %.0f ms\n", ((double) (end - start)) * 1000 / CLOCKS_PER_SEC);
    
    write_bmp ("edges.bmp", header, image);
    
    // if (video) {
        // getchar ();
        // draw_image (image);
        // video_close ( );
    // }
    return 0;
}
