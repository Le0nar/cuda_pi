#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <omp.h>

// Количество прямоугольников для численного интегрирования
#define KS 100000

// Объявляем количество нитей и блоков
#define THREADS 10
#define BLOCKS 10

__global__ void integrate(double* sum, double step, int threads, int blocks)
{
	// Определяем индекс в линейном массиве по формуле
	int idx = threadIdx.x + blockIdx.x * blockDim.x;

	double x = 0;
	for (int i = idx; i < KS; i += threads * blocks)
	{
		x = (i + .5) * step;
		sum[idx] = sum[idx] + 4.0 / (1. + x * x);
	}
}

int main()
{
	int deviceCount = 0;

	printf("Starting...");

	cudaError_t error = cudaGetDeviceCount(&deviceCount);

	if (error != cudaSuccess)
	{
		printf("cudaGetDeviceCount returned %d\n-> %s\n", (int)error, cudaGetErrorString(error));
		return 1;
	}

	deviceCount == 0 ? printf("There are no available CUDA device(s)\n") : printf("%d CUDA Capable device(s) detected\n", deviceCount);

	/*--------- Simple Kernel ---------*/

	int threads = THREADS, blocks = BLOCKS;
	dim3 block(threads);
	dim3 grid(blocks);


	// Объявляем переменные для хранения суммы на хосте и девайсе
	double* sum_h, * sum_d;
	// Определяем шаг
	double step = 1.0f / KS;
	double pi = 0;

	// Выдялем память для host
	sum_h = (double*)malloc(blocks * threads * sizeof(double));

	// Выдялем память для device
	cudaMalloc(&sum_d, blocks * threads * sizeof(double));

	integrate << <grid, block >> > (sum_d, step, threads, blocks);

	// Копирование данных с device на host
	cudaMemcpy(sum_h, sum_d, blocks * threads * sizeof(double), cudaMemcpyDeviceToHost);

	// Сумма результата на хосте
	for (int i = 0;i < threads * blocks; i++)
	{
		pi += sum_h[i];
	}

	pi *= step;
	printf("Pi == %f", pi);

	free(sum_h);
	cudaFree(sum_d);

	system("pause");

	return 0;
}