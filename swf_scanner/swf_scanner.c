#include "zlib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// We cannot have filenames starting with "." or we lowkey die w mid results
int is_filename_char(char character) {
    return isalnum(character) || character == '_' || character == '-';
}

int is_valid_extension(const char* str, int len) {
    if (len < 2 || len > 6) return 0;

    for (int i = 0; i < len; i++) {
        if (!isalnum(str[i])) return 0;
    }

    return 1;
}

void find_filenames(const char* data, long size) {
    int i = 0;
    int matchCount = 0;
    
    while (i < size) {
        if (is_filename_char(data[i]) && !isspace(data[i])) {
            int start = i;
            int lastDot = -1;
            
            while (i < size && (is_filename_char(data[i]) || data[i] == '.')) {
                if (data[i] == '.') {
                    lastDot = i;
                }
                
                i++;
            }
            
            int len = i - start;
            
            if (lastDot != -1 && len > 4) {
                int extLen = (start + len) - (lastDot + 1);
                
                if (is_valid_extension(&data[lastDot + 1], extLen)) {
                    matchCount++;

                    fwrite(&data[start], 1, lastDot - start, stdout);

                    printf("*");
                    fwrite(&data[lastDot], 1, extLen, stdout);
                    
                    printf("\n");
                }
            }
        } else {
            i++;
        }
    }
}

int main(int argc, char** argv) {
    if (argc != 2) {
        printf("Usage: findfiles input.zlib\n");
        return 1;
    }
    
    FILE* fin = fopen(argv[1], "rb");
    if (!fin) {
        printf("Cannot open file\n");
        return 1;
    }
    
    fseek(fin, 0, SEEK_END);
    long inSize = ftell(fin) - 8;
    fseek(fin, 8, SEEK_SET);
    
    unsigned char* inData = (unsigned char*)malloc(inSize);
    fread(inData, 1, inSize, fin);
    fclose(fin);
    
    z_stream stream;
    memset(&stream, 0, sizeof(stream));
    
    if (inflateInit(&stream) != Z_OK) {
        printf("Failed to initialize\n");
        free(inData);
        return 1;
    }
    
    stream.next_in = inData;
    stream.avail_in = inSize;
    
    unsigned long outSize = inSize * 10;
    unsigned char* outData = (unsigned char*)malloc(outSize);
    stream.next_out = outData;
    stream.avail_out = outSize;
    
    int ret = inflate(&stream, Z_FINISH);
    
    if (ret != Z_STREAM_END) {
        printf("Decompression failed\n");
        free(inData);
        free(outData);
        inflateEnd(&stream);
        return 1;
    }
    
    long actualSize = stream.total_out;
    inflateEnd(&stream);
    free(inData);
    
    find_filenames((char*)outData, actualSize);
    
    free(outData);
    return 0;
}