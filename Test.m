%�򵥵���������Ҫ���ڲ��Ը��������ܽ��ܳ������Ч��
clear all
clc
close all

m=imread('lenna256.bmp');

load Hua_K
encrypt=@(m)Hua_2019_Cosine(m,'en',K);
decrypt=@(m)Hua_2019_Cosine(m,'de',K);

c=encrypt(m);
d=decrypt(c);

dd=double(d)-double(m);
nnz(dd)
