
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "..\usr\include\GL\freeglut.h"
#include <stdio.h>
#include <time.h>
#include <math.h>



//�ݹ� �Լ�
void Render();
void Reshape(int w, int h);
void Timer(int id);

//����� ���� �Լ�
void CreateTree();
void Treedraw(float* location, int start);
__global__ void TreeKernel(float* dev_location, float* dev_angle, float len, int find, float angular);


#define TILE_WIDTH 32
const int Dim = 1024;
float* location;
float* angle;
float len = 0.15;
int num = 1;
int start = 0;
float angular = 0.0f;

int main(int argc, char** argv)
{
	printf("����:");
	scanf_s("%d", &num);
	printf("����:");
	scanf_s("%f", &angular);
	location = (float*)malloc(sizeof(float) * 2 * 3);
	angle = (float*)malloc(sizeof(float) * 3);
	for (int i = 0; i < 6; i += 2)
	{
		location[i] = 0.0f;
		location[i + 1] = -0.5f;
	}
	for (int i = 0; i < 3; i++)
	{
		angle[i] = 0;
	}

	//GLUT �ʱ�ȭ
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_RGB);

	//������ ũ�� ���� �� ����
	glutInitWindowSize(Dim, Dim);
	glutCreateWindow("Fractal Tree(GPU)");

	//�ݹ� �Լ� ���
	glutDisplayFunc(Render);
	glutReshapeFunc(Reshape);
	glutTimerFunc(300, Timer, 0);

	cudaSetDevice(0);

	//�̺�Ʈ ó�� ���� ����
	glutMainLoop();

	cudaDeviceReset();
	return 0;
}

void Treedraw(float* location, int start)
{
	if (start == 1)
	{
		glColor3f(0.58, (float)1 / num, 0);
		glLineWidth(3.0f);
		glBegin(GL_LINES);
		glVertex2f(location[0], location[1]);
		glVertex2f(0.0, -1.0);
	}

	int k = 0;
	int n = 0;
	float g = (float)1 / num;
	float r = (float)0.58 / num;
	for (int i = 0; i < (pow(2, start - 1) - 1); i++)
	{
		// ������ ���� ���� ������ ���� �ڵ�
		if (k > pow(2, n))
		{
			g += (float)1 / num;
			r += (float)0.58 / num;
			n++;
		}
		// Left Tree
		glColor3f(0.58 - r, g, 0);
		glLineWidth(3.0f);
		glBegin(GL_LINES);
		glVertex2f(location[2 * i], location[2 * i + 1]);
		glVertex2f(location[4 * i + 2], location[4 * i + 3]);

		// Right Tree
		glColor3f(0.58 - r, g, 0);
		glLineWidth(3.0f);
		glBegin(GL_LINES);
		glVertex2f(location[2 * i], location[2 * i + 1]);
		glVertex2f(location[4 * i + 4], location[4 * i + 5]);
		k++;
	}
	glEnd();
}


void Render()
{
	if (num < start)
	{
		exit(0);
	}
	CreateTree();
	Treedraw(location, start);
	len = 0.89 * len;
	start++;
	int need = pow(2, start + 2) - 1;
	location = (float*)realloc(location, sizeof(float) * 2 * need);
	angle = (float*)realloc(angle, sizeof(float) * need);
	glFinish();
}

void Reshape(int w, int h)
{
	glViewport(0, 0, w, h);
}



void Timer(int id)
{
	glutPostRedisplay();
	glutTimerFunc(500, Timer, 0);
}

void CreateTree()
{
	// ��ǥ ���� �迭�� �ε��� ����� ���� ���� find, check
	int find = pow(2, start + 2) - 1;		// ��ü Ʈ���� �׸��µ� �ʿ��� ��ǥ�� �� ����
	int check = pow(2, start);				// ������ ������ ��ǥ�� ����

	float* dev_location;	// GPU ������ ��ǥ�� �����ϱ� ���� �迭
	float* dev_angle;		// GPU ������ ��ǥ������ ������ �����ϱ� ���� �迭

	cudaError_t cudaStatus = cudaSetDevice(0);
	cudaMalloc((void**)&dev_location, sizeof(float) * 2 * find);
	cudaMalloc((void**)&dev_angle, sizeof(float) * find);
	cudaMemcpy(dev_location, location, sizeof(float) * 2 * find, cudaMemcpyHostToDevice);
	cudaMemcpy(dev_angle, angle, sizeof(float) * find, cudaMemcpyHostToDevice);

	dim3 gridDim(128, 128);
	dim3 blockDim(TILE_WIDTH, TILE_WIDTH);

	clock_t st = clock();
	TreeKernel << <gridDim, blockDim >> > (dev_location, dev_angle, len, check, angular);
	cudaDeviceSynchronize();

	cudaMemcpy(location, dev_location, sizeof(float) * 2 * find, cudaMemcpyDeviceToHost);
	cudaMemcpy(angle, dev_angle, sizeof(float) * find, cudaMemcpyDeviceToHost);

	cudaFree(dev_location);
	cudaFree(dev_angle);

	if (start > 0)
		printf("%d��° Elapsed time = %u ms\n", start, clock() - st);
}

__global__ void TreeKernel(float* dev_location, float* dev_angle, float len, int check, float angular)
{
	int x = blockIdx.x * TILE_WIDTH + threadIdx.x;
	int y = blockIdx.y * TILE_WIDTH + threadIdx.y;

	int index = x + y * 4096;
	int destination = 2 * (check - 1) + 2 * index;	// ���� Ʈ���� ��ǥ ������ ���� �ε���

	// ���� index (0 ~ check-1) ���� dev_location�� ��ǥ���� ����Ǿ� ����
	if (index < check)
	{
		float a = dev_location[destination];
		float b = dev_location[destination + 1];
		float angle = dev_angle[check - 1 + index];

		// ���� Ʈ���� x,y ��ǥ
		float lx = a + len * sin(angle - angular);
		float ly = b + len * cos(angle - angular);
		dev_location[2 * destination + 2] = lx;
		dev_location[2 * destination + 3] = ly;
		dev_angle[2 * check + 2 * index - 1] = angle - angular;		// ������ Ʈ���� ���ϴ� ���� ����

		// ������ Ʈ���� x,y ��ǥ
		float rx = a + len * sin(angle + angular);
		float ry = b + len * cos(angle + angular);
		dev_location[2 * destination + 4] = rx;
		dev_location[2 * destination + 5] = ry;
		dev_angle[2 * check + 2 * index] = angle + angular;		// ���� Ʈ���� ���ϴ� ���� ����
	}
}