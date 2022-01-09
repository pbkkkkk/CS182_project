
clearvars; clc;
%% Basic setting
n = 500;       %%%  n = the number of nodes
K = 2;          %%% K = the number of blocks
m = n/K;        %%% m = the block size

%% ground truth 
Xt =  kron(eye(K), ones(m)); 
Xt(Xt==0)=-1;                                    %%% Xt = the true cluster matrix
xt = [ones(m,1); -ones(m,1)];           %%%  xt = the true cluster vector

%% generate an adjacency matrix A by Binary SBM
a = 9; b = 2;        %%%  choose the constants alpha, beta in p, q, resp.
% sqrt(a) - sqrt(b) - sqrt(2)
p = a*log(n)/n;       %%%  p = the within-cluster connecting probability; 
q = b*log(n)/n;       %%%  q = the across-cluster connecting probability.       

for repeat = 1:5 %%%% 
    
            Ans11 = rand(m); Al11 = tril(Ans11,-1); 
            As11 = Al11 + Al11'+diag(diag(Ans11)); clear Ans11 Al11
            A11 = double(As11<=p); A11 = sparse(A11); clear As11
            As12 = rand(m);
            A12 = double(As12<=q); A12 = sparse(A12); clear As12
            Ans22 = rand(m); Al22 = tril(Ans22,-1); 
            As22 = Al22 + Al22' + diag(diag(Ans22)); clear Ans22 Al22
            A22 = double(As22<=p); A22 = sparse(A22); clear As22
            A = ([A11,A12;A12',A22]); clear A11 A12 A22
            A = sparse(A);

            %% initial point generated by uniform distribution over the sphere
            x0 = randn(n,1); x0 = x0/norm(x0);
            maxiter = 1e3; tol = 1e-4; report_interval = 1; total_time = 1e3; print = 1;
            
            %% PI + PPM for Regularized MLE            
            opts = struct('T', maxiter, 'tol', tol, 'report_interval', report_interval,...
                'total_time', total_time, 'print', print); %%% choose the parameters in PPM
            tic; [x_PPM, iter_PPM, val_collector_PPM, itergap_PPM] = PPM(A, x0, xt, opts); time_PPM=toc; 
            dist_PPM = norm(x_PPM*x_PPM'-Xt, 'fro');
            
            semilogy(itergap_PPM+1e-8, '-s', 'LineWidth', 2, 'MarkerSize', 6); hold on;           
            
end 

ylim([1e-8, 1e6]);
xlabel('Iterations'); ylabel('distance to ground truth');
