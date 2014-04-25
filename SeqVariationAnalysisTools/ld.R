args <- commandArgs(trailingOnly = TRUE)
pop=as.character(args[1])
print(pop)
ld <- read.table(paste(pop,".ld",sep=''),header=T)
a <- data.frame("pop" = character(), "distance_bp"= numeric(),"num_obs"=numeric() ,"mean_ld" = numeric(),"sd_ld" = numeric())
md <- mean(ld$BP_B[ld$BP_B-ld$BP_A<1000]-ld$BP_A[ld$BP_B-ld$BP_A<1000])
no <- length(ld$BP_B[ld$BP_B-ld$BP_A<1000]-ld$BP_A[ld$BP_B-ld$BP_A<1000])
mn <- mean(ld$R[ld$BP_B-ld$BP_A<1000])
s <- sd(ld$R[ld$BP_B-ld$BP_A<1000])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))

min=1000
max=10000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <- length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))

min=10000
max=50000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <- length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))
min=50000
max=100000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <- length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))
min=200000
max=300000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <- length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))
min=300000
max=400000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <- length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))
min=400000
max=500000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <-length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))
min=500000
max=600000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <- length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))
min=600000
max=700000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <- length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))
min=700000
max=800000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <- length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))
min=800000
max=900000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <- length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))
min=900000
max=1000000
md <- mean(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
no <- length(ld$BP_B[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A) <max]-ld$BP_A[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max])
mn<-mean(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
s<-sd(ld$R[(ld$BP_B-ld$BP_A)>min & (ld$BP_B-ld$BP_A)<max ])
a<- rbind(a,data.frame("pop" = pop, "distance_bp"= md,"num_obs"=no ,"mean_ld" = mn,"sd_ld" = s))
write.table(x=a,file=paste(pop,"_ld_results.txt",sep=''))
