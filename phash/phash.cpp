// damn near 80% of this code was AI-generated
// i aint use C++ a day in my life so we gotta plow through somehow Unforch
// this is why this program is made using BATCH :sob: i aint dealing with backwards compatibility in a language i don't know
// it works tho

#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <cmath>
#include <stdint.h>

const int WIDTH = 32;
const int HEIGHT = 32;
const int FRAME_SIZE = WIDTH * HEIGHT;

const float PI = 3.14159265358979323846f;
float cos_table_x[32][8];
float cos_table_y[32][8];

// Compute 2D DCT on 32x32 input and return top-left 8x8 coefficients
void dct8x8(const uint8_t* input, float out[8][8]) {
    for (int u = 0; u < 8; ++u) {
        for (int v = 0; v < 8; ++v) {
            float sum = 0.0f;
            for (int x = 0; x < WIDTH; ++x) {
                for (int y = 0; y < HEIGHT; ++y) {
                    float pixel = static_cast<float>(input[y * WIDTH + x]);
                    sum += pixel * cos_table_x[x][u] * cos_table_y[y][v];
                }
            }
            float cu = (u == 0) ? (1.0f / std::sqrt(2.0f)) : 1.0f;
            float cv = (v == 0) ? (1.0f / std::sqrt(2.0f)) : 1.0f;
            out[u][v] = 0.25f * cu * cv * sum;
        }
    }
}

// Compute 64-bit perceptual hash from 32x32 frame
uint64_t compute_phash(const uint8_t* frame) {
    float dct[8][8];
    dct8x8(frame, dct);

    // Compute average of top-left 8x8 coefficients
    float total = 0.0f;
    for (int u = 0; u < 8; ++u)
        for (int v = 0; v < 8; ++v)
            total += dct[u][v];
    float avg = total / 64.0f;

    // Build 64-bit hash
    uint64_t hash = 0;
    for (int u = 0; u < 8; ++u) {
        for (int v = 0; v < 8; ++v) {
            hash <<= 1;
            if (dct[u][v] > avg) hash |= 1;
        }
    }
    return hash;
}

// XP-safe 64-bit hex parsing
uint64_t parse_hex64(const char* str) {
    uint32_t hi = 0, lo = 0;
    if (sscanf(str, "%8x%8x", &hi, &lo) != 2) {
        fprintf(stderr, "Invalid hash format\n");
        return 0;
    }
    return ((uint64_t)hi << 32) | lo;
}

// XP-safe Hamming distance
int hamming(uint64_t a, uint64_t b) {
    if (a == b) return 0;
    uint32_t hi = static_cast<uint32_t>((a ^ b) >> 32);
    uint32_t lo = static_cast<uint32_t>((a ^ b) & 0xFFFFFFFF);
    int count = 0;
    while (hi) { count += hi & 1; hi >>= 1; }
    while (lo) { count += lo & 1; lo >>= 1; }
    return count;
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cout << "Usage: phash.exe <frames.raw> <hash1> [hash2 hash3 ...]\n";
        return 1;
    }

    const char* input_file = argv[1];

    // Load all hashes
    std::vector<uint64_t> target_hashes;
    for (int i = 2; i < argc; ++i)
        target_hashes.push_back(parse_hex64(argv[i]));

    FILE* f = fopen(input_file, "rb");
    if (!f) {
        std::cerr << "Cannot open file\n";
        return 1;
    }

    // Precompute cosine tables
    for (int x = 0; x < WIDTH; ++x)
        for (int u = 0; u < 8; ++u)
            cos_table_x[x][u] = std::cos((2*x + 1) * u * PI / 64.0f);

    for (int y = 0; y < HEIGHT; ++y)
        for (int v = 0; v < 8; ++v)
            cos_table_y[y][v] = std::cos((2*y + 1) * v * PI / 64.0f);

    uint8_t frame[FRAME_SIZE];
    int frame_num = 0;

    while (fread(frame, 1, FRAME_SIZE, f) == FRAME_SIZE) {
        uint64_t hash = compute_phash(frame);

        for (size_t i = 0; i < target_hashes.size(); ++i) {
            int dist = hamming(hash, target_hashes[i]);
            if (dist <= 4 && target_hashes[i] != 0)
                std::cout << std::hex << std::setw(16) << std::setfill('0') << target_hashes[i] << " "
                          << std::hex << hash << " " << std::dec << dist << "\n";
        }

        frame_num++;
    }

    fclose(f);
    return 0;

}
