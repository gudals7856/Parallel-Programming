
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include "..\usr\include\GL\freeglut.h"

const int Dim = 1024;
int n = 1;
int num = 0;

// ����� ���� �Լ�
void CreateTree();
void Tree(float x, float y, float angle, int n, float len);
void Timer(int id);

int main(int argc, char** argv)
{

	printf("����:");
	scanf_s("%d", &num);
	// GLUT �ʱ�ȭ
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_RGB);

	// ������ ũ�� ���� �� ����
	glutInitWindowSize(Dim, Dim);
	glutCreateWindow("Fractal Tree (CPU)");

	// �ݹ� �Լ� ���
	glutDisplayFunc(CreateTree);
	glutTimerFunc(300, Timer, 0);
	 

	// �̺�Ʈ ó�� ���� ����
	glutMainLoop();
	printf("Done");
	return 0;
}


void Timer(int id)
{
	glutPostRedisplay();
	glutTimerFunc(500, Timer, 0);
}


void CreateTree()
{
	if (n > num)
	{
		glClear(GL_COLOR_BUFFER_BIT);
		n = 1;
	}

	float x = 0.0f;			// �ʱ� x��ǥ
	float y = -1.0f;		// �ʱ� y��ǥ
	float angle = 0;		// ���� Ʈ���� ���Ҷ� ���ϴ� ��������
	float len = 0.3;		// �ʱ� Ʈ�� ������ ����
	clock_t st = clock();
	Tree(x, y, angle, n, len);
	glFlush();
	printf("%d��° ������ Elaspsed time:%u ms\n",n, clock() - st);
	n++;
}

void Tree(float x, float y, float angle, int n, float len)
{
	float wid = (float)(num - n)/4;		// ������ �ʺ� ��������
	
	// RGB �� ���
	float r = (float)0.5- 0.5 / n;		
	float g = (float)0.45 / n;
	float b = (float)0.12-0.12 / n;

	// ���� Ʈ���� ���ϴ� ��ǥ
	float x2 = x + len * sin(angle);
	float y2 = y + len * cos(angle);
	glColor3f(r, g, b);
	glLineWidth(wid);
	glBegin(GL_LINES);
	glVertex2f(x, y);
	glVertex2f(x2, y2);
	glEnd();
	
	// ���� Ʈ�� ������ ���� ����Լ��� ȣ��
	if (n > 0)
	{
		Tree(x2, y2, angle + 25.5, n - 1, len * 0.8);
		Tree(x2, y2, angle - 25.5, n - 1, len * 0.8);
	}
}
	


