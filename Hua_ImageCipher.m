%%================================================================================
%This functionto do image encryption using the reference in
%         [1]. Hua, Zhongyun, et al. "2D Sine Logistic modulation map for image encryption." 
%              Information Sciences 297 (2015): 80-94.
%All copyrights are reserved by Zhongyun Hua. E-mial:huazyum@gmail.com
%All following source code is free to distribute, to use, and to modify
%    for research and study purposes, but absolutely NOT for commercial uses.
%If you use any of the following code in your academic publication(s), 
%    please cite the corresponding paper. 
%If you have any questions, please email me and I will try to response you ASAP.
%It worthwhile to note that all following source code is written under MATLAB R2010a
%    and that files may call built-in functions from specific toolbox(es).
%%================================================================================
%%
function varargout = Hua_ImageCipher(P,para,K)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main function to implement image cipher
% P:    the input image;
% para: operation type, 'encryption' or 'decryption';
% K:    the key, when para = 'encryption', it can be given or can not be given; 
%       when para = 'decryption', it must be given;
% varargout: when K is not given, return the result and the randomly
%            generated key; when K is given, return the result.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% to get the key
if ~exist('K','var') && strcmp(para,'encryption')
    K = round(rand(1,256));
    OutNum = 2;
elseif ~exist('K','var')  && strcmp(para,'decryption')
    error('Can not dectrypted without a key');
else
    OutNum = 1;
end

%%extract the key
 
tran = @(K,low,high) sum(K(low:high).*2.^(-(1:(high-low+1))));
x0 = tran(K,1,52);
y0 = tran(K,53,104);
a0 = tran(K,105,156);
T = tran(K,157,208);

Tran = blkproc(K(209:256),[1,24],@(x) bi2de(x));
%% 
[r, c] = size(P);
%generating chaotic sequence one
 x = mod(x0 + Tran(1)*T,1);
 y = mod(y0 + Tran(1)*T,1);
 a = 0.9 + mod(a0 + Tran(1)*T,0.1);

 S1 = ChaoticSeq(x,y,a,r,c);
 
 %generating chaotic sequence two
 x = mod(x0 + Tran(2)*T,1);
 y = mod(y0 + Tran(2)*T,1);
 a = 0.9 + mod(a0 + Tran(2)*T,0.1);

 S2 = ChaoticSeq(x,y,a,r,c);
 
 %% To do the encryption/decryption
 C = double(P);
switch para
    case 'encryption'
            % round one
             
             C = ChaoticMagicTrans(C,para,S1);
             C = Substitution(C,para,S1);
%              round two
             C = ChaoticMagicTrans(C,para,S2);
             C = Substitution(C,para,S2);

    case 'decryption'
             C = Substitution(C,para,S2);
            C = ChaoticMagicTrans(C,para,S2);
             
            C = Substitution(C,para,S1);
            C = ChaoticMagicTrans(C,para,S1);

end

%% 
if OutNum == 1
    varargout{1} = C;
else
    varargout{1} = C;
    varargout{2} = K;
end
end % end of the function ImageCipher

function  S = ChaoticSeq(x,y,a,r,c)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is to generate chaotic matrix using 
% 2D Sine Logistic modulation map with the given initial condition
% and size
% x,y,a: the given initial condition;
% r,c; the row and column number of the matrix
%
% S: the generated chaotic matrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
X = zeros(1,r*c);
Y = X;

% exclude the first 2000 iteration values
% for m = 1:2000
%     x = a*(sin(pi*y)+3)*x*(1-x);
%     y = a*(sin(pi*x)+3)*y*(1-y);
% end

for m = 1:r*c
    x = a*(sin(pi*y)+3)*x*(1-x);
    y = a*(sin(pi*x)+3)*y*(1-y);
    X(m) = x;
    Y(m) = y;
end

X = reshape(X,[r,c]);
Y = reshape(Y,[r,c]);

S = X+Y;
end % end of the function ChaoticSeq

function C = ChaoticMagicTrans(P,para,S)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is to do circle magic tranform (CMT)
% P: input image ;
% para: operation type, 'encryption' or 'decryption';
% S: input chaotic matrix, the same size as P
%
% C: CMT result
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

[r,c] = size(P);
[X,S_c] = sort(S,1);
C = zeros(r,c);

switch para
    case 'encryption'
        for m = 1:r
            for n = 1:c
                C(S_c(m,n),n) = P(S_c(m,  mod(n+  m -1,c)+1),mod(n+m-1,c)+1);
            end
        end
    case 'decryption'

            for m = 1:r
                for n = 1:c
                    C(S_c(m,n),n) = P(S_c(m,  mod(n+ c-  m -1,c)+1),mod(n+ c -  m-1,c)+1);
                end
            end
end
C=uint8(C);
end % end of the function ChaoticMagicTrans

function C = Substitution(P,para,S)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is to do substitution
% P: input image ;
% para: operation type, 'encryption' or 'decryption';
% S: input chaotic matrix, the same size as P
%
% C: substitution result
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%常见句柄
add_mod=@(a,b)uint8(mod(double(a)+double(b),256));%模和
inv_add_mod=@(c_sum,b)uint8(mod(double(c_sum)-double(b),256)); %已知模和结果，和一个变量，求另一个
sub_mod=@(a,b)uint8(mod(double(a)-double(b),256));%模减
inv_sub_mod_a=@(c_sub,b)uint8(mod(double(c_sub)+double(b),256));%已知模减结果和被减数b，求减数a
inv_sub_mod_b=@(c_sub,a)uint8(mod(double(c_sub)-double(a),256));%已知模减结果和减数a，求被减数b
%常见句柄

P = double(P);
[r,c] = size(P);


S = floor(S.*2^32);
S = mod(S, 256);

switch para
    case 'encryption'
        % row substitution
        for m = 1:r
            for n = 1:c
                  if n == 1
%                       T(m,n) = mod(P(m,n) + S(m,n)+P(m,c) , F);
                      T(m,n) = add_mod(P(m,n),double(S(m,n))+double(P(m,c)));
                  else
%                       T(m,n) = mod(P(m,n) + S(m,n)+T(m,n-1) , F);
                      T(m,n) = add_mod(P(m,n),double(S(m,n))+double(T(m,n-1)));
                  end
                 
            end
        end
         % column substitution
        for n = 1:c
            for m = 1:r
                  if m == 1
%                       C(m,n) = mod(T(m,n)+S(m,n) + T(r,n), F);
                      C(m,n) = add_mod(T(m,n),double(S(m,n))+double(T(r,n)));
                  else
%                       C(m,n) = mod(T(m,n)+S(m,n)+C(m-1,n), F);
                      C(m,n) = add_mod(T(m,n),double(S(m,n))+double(C(m-1,n)));
                  end
            end
        end
        
    case 'decryption'
        %column inverse substitution
         for n = 1:c
            for m = r:-1:1
                  if m == 1
%                       T(m,n) = mod(P(m,n)-S(m,n)-T(r,n), 256);
                      T(m,n) = inv_add_mod(P(m,n),double(S(m,n))+double(T(r,n)));
                  else
%                       T(m,n) = mod(P(m,n)-S(m,n)-P(m-1,n), 256);
                      T(m,n) = inv_add_mod(P(m,n),double(S(m,n))+double(P(m-1,n)));
                  end
            end
         end
         
         %row inverse substitution

         for m = 1:r
            for n = c:-1:1
                if n == 1
%                    C(m,n) = mod(T(m,n) - S(m,n) - C(m,c), F);
                   C(m,n) = inv_add_mod(T(m,n),double(S(m,n))+double(C(m,c)));
                else
%                    C(m,n) = mod(T(m,n) - S(m,n) - T(m,n-1), F);
                   C(m,n) = inv_add_mod(T(m,n),double(S(m,n))+double(T(m,n-1)));
                end                
            end
         end
end
end % end of the function Substitution
