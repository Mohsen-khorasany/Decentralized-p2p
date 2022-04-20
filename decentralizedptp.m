clc; clear; close all;

%% Input parameters
FIT= 10; % Feed-in tariff
TOU=23; % Market price
M=100; %Big number for distance calculation
gamma=0.5; %permiums limit

%%Bidding step

% Sellers parameters
seller_data = csvread('sellers1.csv', 1, 0);  
I_s= transpose(seller_data(:,1)); %Seller ID
Q_s= -transpose(seller_data(:,2)); %Seller offer-Quantity 
P_s= transpose(seller_data(:,3)); %Seller offer-Price
L_s= transpose(seller_data(:,4)); %Seller location ID
R_s= transpose(seller_data(:,5)); %Seller Reputation
G_s= transpose(seller_data(:,6)); %Seller Green energy index
alpha_L_s= transpose(seller_data(:,7)); %Seller location permium
alpha_R_s= transpose(seller_data(:,8)); %Seller reputation permium
alpha_G_s= transpose(seller_data(:,9)); %Seller green energy permium
Ns= size(seller_data,1); %Number of sellers

% Buyers parameters
buyer_data = csvread('buyers1.csv', 1, 0);
I_b= transpose(buyer_data(:,1)); %Buyer ID
Q_b= transpose(buyer_data(:,2)); %Buyer offer-Quantity
P_b= transpose(buyer_data(:,3)); %Buyer offer-Price
L_b= transpose(buyer_data(:,4)); %Buyer location ID
R_b= transpose(buyer_data(:,5)); %Buyer Reputation
G_b= transpose(buyer_data(:,6)); %Buyer Green energy index
alpha_L_b= transpose(buyer_data(:,7)); %Buyer location permium
alpha_R_b= transpose(buyer_data(:,8)); %Buyer reputation permium
alpha_G_b= transpose(buyer_data(:,9)); %Buyer green energy permium
Nb= size(buyer_data,1); %Number of buyers


%%Checking STV constraint equation (2)
for i=1:Ns
    if alpha_L_s(i) + alpha_R_s(i) + alpha_G_s(i) > gamma .*(P_s(i)) %if STV is not satisfied 
        Q_s(i)= -1000; %Change seller's offer to a large negative value so that seller can not trade
    end
end

for j=1:Nb
    if alpha_L_b(i) + alpha_R_b(i) + alpha_G_b(i) > gamma .*(P_b(i)) %if STV is not satisfied
        Q_b(i)= 1000; %Change buyer's offer to a large value so that buyer can not trade
    end
end



%% Forming Utility matrices
U_s= zeros(Ns,Nb); % Sellers utility matrix
TP_s= zeros(Ns,Nb); % Temporary price matrix for sellers 
U_b = zeros(Nb,Ns); % Buyers utility matrix
TP_b= zeros(Nb,Ns); % Temporary price matrix for buyers 
lambda= zeros(Ns,Nb); %Transaction price matrix
for i=1:Ns
    for j=1:Nb
        TP_s(i,j)= P_s(i) - (alpha_L_s(i) .*(1- abs(L_s(i)-L_b(j))./M) +alpha_R_s(i).* R_b(j) + alpha_G_s(i) .* G_b(j)); %equation (15) and (16) 
        
        TP_b(j,i)= P_b(j) + (alpha_L_b(j) .*(1- abs(L_s(i)-L_b(j))./M) +alpha_R_b(j).* R_s(i) + alpha_G_b(j) .* G_s(i)); %equation (17) and (18) 
        
        lambda(i,j)=  (TP_s(i,j) +  TP_b(j,i))./2; %equation (14)
        
        U_b(j,i)= min(Q_s(i),Q_b(j)).*(P_b(j)-lambda(i,j)); %equation (12)
        U_s(i,j)= min(Q_s(i),Q_b(j)).*(lambda(i,j)-P_s(i)); %equation (13)
    end
end


%% Matching step
MM_s=zeros(Ns,Nb); % Sellers matching matrix

%Sellers matching matrix calculation
for i=1:Ns %Start from the seller with the lowest offer (sellers are arranged in ascending order in input file)
  [B,idx]=sort(U_s(i,:),'descend'); %Arrange all avaialble buyers to seller i based on the utility
   for j=[idx] %for all arranged buyers
        if  (Q_s(i) - Q_b(j)) >-3 %check if the seller can provide the requested power
            MM_s(i,j)=1; % Set Mtaching index to 1
            Q_b(j)=10000; % Change the offer of buyer to a big number so that other sellers can not choose it
            Q_s(i)=-10000; % Change the offer of seller to a big number so that other buyers can not choose it
        else % if the seller cannot provide the requested power
            
            MM_s(i,j)=0;    % Set Mtaching index to 0
        end
    end
    
end

%Reset the values in Q_b and Q_s before calculating buyers matching matrix
Q_b= transpose(buyer_data(:,2)); %Buyer offer-Quantity
Q_s= -transpose(seller_data(:,2)); %Seller offer-Quantity

MM_b=zeros(Nb,Ns); % Buyers matching matrix
%Buyers matching matrix calculation
for j=1:Nb %Start from the buyer with the highest bid (buyers are arranged in descending order in input file)
  [BB,idxx]=sort(U_b(j,:),'descend'); %Arrange all available buyers to buyer j based on the utility
  
   for i=[idxx] %for all arranged sellers
        if  (Q_b(j) - Q_s(i)) <5 %check if the seller can provide the requested power
            if MM_s(i,j)~=0 %Check if the offer of seller is vailable 
                MM_b(j,i)=1; %Set matching index to 1
                Q_s(i)=-10000; % Change the offer of buyer to a big number so that other sellers can not choose it
                Q_b(j)=10000; % Change the offer of seller to a big number so that other buyers can not choose it
            end
            
        else % if the seller cannot provide the requested power
            
          MM_b(j,i)=0;   % Set Mtaching index to 0
        end
    end
    
end
%Reset the values in Q_b and Q_s 

Q_b= transpose(buyer_data(:,2)); 
Q_s=- transpose(seller_data(:,2));



figure %quantity
w1=0.8;
bar(Q_b,w1,'FaceColor',[0.2 0.2 0.5])
hold on
QSS=[Q_s([3 4]),0,Q_s([12 22 11 16 13 10]),0,Q_s(6),0, Q_s([14 15 21]), 0, Q_s([9 19 20 17 7 1 2 5]),0,0 ,Q_s(23),0, Q_s([18 8 24])];
w2=0.5;
bar(QSS,w2,'FaceColor',[0.3 0.9 0.9])

plot(min(Q_b,QSS), '-*','LineWidth',1,'MarkerSize',6,'Color','#D95319')
legend({'Buyers Offers','Sellers Offers', 'Traded Quanitity'},'Location','northeast')
hold on
xlabel('Matched prosumers','FontSize',10, 'fontname','times new roman')
ylabel('Power (kW)','FontSize',10, 'fontname','times new roman')
set(gca,'Xtick',1:1:31,'XTickLabel',{I_b})
set(gca,'fontname','times new roman', 'FontSize',10)
xtickangle(90)
 
figure %Matching
subplot(2,1,1)
spy(MM_b','ko',4)
xlabel({'Buyers (\it I_n)';'(a)'},'FontSize',10, 'fontname','times new roman')
ylabel('Sellers (\it I_n)','FontSize',10, 'fontname','times new roman')
set(gca,'Xtick',1:1:31,'XTickLabel',{I_b})
set(gca,'Ytick',1:1:24,'YTickLabel',{I_s})
set(gca,'fontname','times new roman', 'FontSize',8)
xtickangle(90)
hold on
xbox1 =[0 0 4.5 4.5];
ybox1= [0 8.5 8.5 0];
patch(xbox1, ybox1, 'black', 'Facecolor', 'green', 'FaceAlpha',0.2)
hold on
xbox2 =[4.5 4.5 19.5 19.5];
ybox2= [8.5 13.5 13.5 8.5];
patch(xbox2, ybox2, 'black', 'Facecolor', 'green', 'FaceAlpha',0.2)

hold on
xbox3 =[19.5 19.5 23.5 23.5];
ybox3= [13.5 19.5 19.5 13.5];
patch(xbox3, ybox3, 'black', 'Facecolor', 'green', 'FaceAlpha',0.2)

hold on
xbox4 =[23.5 23.5 32 32];
ybox4= [19.5 25 25 19.5];
patch(xbox4, ybox4, 'black', 'Facecolor', 'green', 'FaceAlpha',0.2)

hold on
xbox5 =[0 0 32 32];
ybox5= [0 25 25 0];
patch(xbox5, ybox5, 'black', 'Facecolor', 'black', 'FaceAlpha',0.1)

subplot(2,1,2)
MM_np=[0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0;0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1;1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0;0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
spy(MM_np','ko',4)
xlabel({'Buyers (\it I_n)';'(b)'},'FontSize',10, 'fontname','times new roman')
ylabel('Sellers (\it I_n)','FontSize',10, 'fontname','times new roman')
set(gca,'Xtick',1:1:31,'XTickLabel',{I_b})
set(gca,'Ytick',1:1:24,'YTickLabel',{I_s})
set(gca,'fontname','times new roman', 'FontSize',8)
xtickangle(90)
hold on
xbox1 =[0 0 4.5 4.5];
ybox1= [0 8.5 8.5 0];
patch(xbox1, ybox1, 'black', 'Facecolor', 'green', 'FaceAlpha',0.2)
hold on
xbox2 =[4.5 4.5 19.5 19.5];
ybox2= [8.5 13.5 13.5 8.5];
patch(xbox2, ybox2, 'black', 'Facecolor', 'green', 'FaceAlpha',0.2)

hold on
xbox3 =[19.5 19.5 23.5 23.5];
ybox3= [13.5 19.5 19.5 13.5];
patch(xbox3, ybox3, 'black', 'Facecolor', 'green', 'FaceAlpha',0.2)

hold on
xbox4 =[23.5 23.5 32 32];
ybox4= [19.5 25 25 19.5];
patch(xbox4, ybox4, 'black', 'Facecolor', 'green', 'FaceAlpha',0.2)

hold on
xbox5 =[0 0 32 32];
ybox5= [0 25 25 0];
patch(xbox5, ybox5, 'black', 'Facecolor', 'black', 'FaceAlpha',0.1)



figure %Utility 
clims = [0 1];  
imagesc((U_s./max(U_s)+U_b'./max(U_b)')./2,clims)
hold on
map2= [0.95 0.95 0.95; 0.01 0.98 0.01;0.12 0.79 0.12;0.17 0.62 0.17;0.18 0.4 0.18];
colormap(map2);

hold on  
c1 = colorbar;
hold on
spy(MM_np','ro',4)
xlabel('Buyers (\it I_n)','FontSize',10, 'fontname','times new roman')
ylabel('Sellers (\it I_n)','FontSize',10, 'fontname','times new roman')
set(gca,'Xtick',1:1:31,'XTickLabel',{I_b})
set(gca,'Ytick',1:1:24,'YTickLabel',{I_s})
set(gca,'fontname','times new roman', 'FontSize',8)
xtickangle(90)

figure %dailyperformance of prosumers
%P2P trade of prosumers
p2_p2p=[0.018	0.169	0.181	0.294	0.172	0.205	0.338	0.337	-1.017	-2.482	0.143	-0.955	-0.99	-0.962	-0.801	-1.393	-0.945	-1.122	-1.067	-1.202];
p16_p2p=[-0.472	-0.684	-1.017	-1.247	-1.276	-1.43	-1.711	-2.004	-2.776	-3.063	-2.29	-2.614	-3.036	-2.611	-2.394	-2.589	-1.942	-1.732	-1.678	-1.346];
p39_p2p=[-0.539	-0.227	-0.792	-0.242	0.051	2.115	2.171	2.004	2.063	2.224	2.199	2.234	2.263	2.209	2.21	0.185	0.148	0.088	0.097	0.102];

%Daily load and generation of prsumers (first row load, second row generation)
p2_LG=[0.187	0.19	0.187	0.185	0.183	0.182	0.183	0.189	0.182	0.191	0.186	0.186	0.325	0.21	0.182	0.119	0.182	0.125	0.278	0.283	0.225	0.257	1.623	3.095	0.482	1.561	1.578	1.518	1.314	1.856	1.351	1.453	1.323	1.371	1.566	1.553	1.589	0.83	1.119	0.815	0.497	0.331	0.306	0.355	0.316	0.302	0.222 0.189
	0	0	0	0.000	0	0	0	0	0	0	0	0	0.013	0.106	0.2	0.288	0.363	0.419	0.45	0.488	0.563	0.594	0.606	0.613	0.625	0.606	0.588	0.556	0.513	0.463	0.406	0.331	0.256	0.169	0.088	0.031	0.013	0.013	0	0	0	0	0	0	0	0	0.006 0];
p16_LG=[0.265	0.232	0.188	0.261	0.395	0.241	0.158	0.194	0.153	0.172	0.167	0.141	0.345	0.282	0.472	0.684	1.017	1.247	1.276	1.43	1.711	2.004	2.776	3.063	2.29	2.614	3.036	2.611	2.394	2.589	1.942	1.732	1.678	1.346	0.927	0.938	1.083	0.908	1.015	1.593	1.275	0.894	0.473	0.491	0.43	0.688	0.222 0.298];

p39_LG=[0.145	0.154	0.162	2.204	0.99	0.106	0.11	0.196	0.142	0.135	0.113	0.102	0.115	0.115	0.545	0.24	0.861	0.417	0.174	0.148	0.123	0.321	0.281	0.132	0.176	0.141	0.125	0.172	0.159	0.184	0.196	0.237	0.191	0.154	0.766	0.903	0.877	1.172	0.996	0.911	0.553	0.347	0.316	0.323	0.296	0.314	0.405 0.25	
0	0	0	0	0	0	0	0	0	0	0	0	0	0.006	0.006	0.013	0.069	0.175	0.225	0.263	0.294	0.325	0.344	0.356	0.375	0.375	0.388	0.381	0.369	0.369	0.344	0.325	0.288	0.256	0.213	0.163	0.1	0.031	0	0	0	0	0	0	0	0	0 0];

subplot(2,1,1)
plot(p2_LG(1,:)-p2_LG(2,:),'-^','LineWidth',1,'MarkerSize',4, 'Color','#0072BD')
hold on
% plot(p2(2,:),'-b','LineWidth',1)
hold on
plot(p16_LG,'-ob','LineWidth',1,'MarkerSize',4,'Color','#D95319')
hold on
plot(p39_LG(1,:)-p39_LG(2,:),'-sr','LineWidth',1,'MarkerSize',4,'Color','#EDB120')
hold on
% plot(p39(2,:),'-.b','LineWidth',1)
hold on
plot([0,48],[0,0],'-.k','LineWidth',1)
hold on
xbox5 =[15 15  34 34];
ybox5= [-0.5 3.5 3.5 -0.5];
patch(xbox5, ybox5, 'black', 'Facecolor', 'black', 'FaceAlpha',0.07)
% plot([0 10],[0 0], '--','LineWidth',2)
xlabel({'Time (hh:mm)';'(a)'},'FontSize',12, 'fontname','times new roman')
ylabel('Net Power (kW)','FontSize',12, 'fontname','times new roman')
% set(gca,'Xtick',1:1:10,['10:30',	'11:00',	'11:30',	'12:00',	'12:30',	'13:00',	'13:30',	'14:00',	'14:30'	,'15:00'],'XTickLabel',{I_b})
% set(gca,'Ytick',1:1:24,'YTickLabel',{I_s})
xticks([1:2:48])
xticklabels({'1:00','2:00','3:00','4:00','5:00','6:00','7:00','8:00','9:00','10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00','18:00','19:00','20:00','21:00','22:00','23:00','0:00'})
legend('P2', 'P16','P39','Orientation','horizontal');
xtickangle(90)
xlim([1,48])
ylim([-0.5,3.5])
set(gca,'fontname','times new roman', 'FontSize',12)
subplot(2,1,2)
bar([p39_p2p; p16_p2p; p2_p2p]')
% bar([buy39]','r')
% hold on
% bar([sell16]','b')
xticks([1:1:20])
xticklabels({'8:00','8:30','9:00','9:30','10:00','10:30','11:00','11:30','12:00','12:30','13:00','13:30','14:00','14:30','15:00','15:30','16:00','16:30','17:00','17:30'})
xtickangle(90)
ylim([-3.5,2.5])
xlabel({'Time (hh:mm)';'(b)'},'FontSize',12, 'fontname','times new roman')
ylabel('Traded power (kW)','FontSize',12, 'fontname','times new roman')
set(gca,'fontname','times new roman', 'FontSize',12)
legend('\fontname{Times New Roman} P2','\fontname{Times New Roman} P16', '\fontname{Times New Roman} P39','Orientation','horizontal');


%Export output data
csvwrite('matchs.csv', MM_s);
csvwrite('matchb.csv', MM_b);
csvwrite('utilitys.csv', U_s);
csvwrite('utilityb.csv', U_b);
csvwrite('marketp.csv', lambda);
csvwrite('finaloffer.csv',  TP_s);
csvwrite('finalbid.csv',  TP_b);
csvwrite('31buyer.csv',  buyer_data);
csvwrite('24seller.csv',  seller_data);
