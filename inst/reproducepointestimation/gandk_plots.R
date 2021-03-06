library(winference)
rm(list = ls())
theme_set(theme_bw())
theme_update(axis.text.x = element_text(size = 20),
             axis.text.y = element_text(size = 20),
             axis.title.x = element_text(size = 25, margin=margin(20,0,0,0)),
             axis.title.y = element_text(size = 25, angle = 90, margin = margin(0,20,0,0)),
             legend.text = element_text(size = 20),
             legend.title = element_text(size = 20),
             title = element_text(size = 30),
             strip.text = element_text(size = 25),
             strip.background = element_rect(fill="white"),
             panel.spacing = unit(2, "lines"),
             legend.position = "bottom")
set.seed(11)

source("gandk_functions.R")

prefix = ""

true_theta = c(3,1,2,0.5)

#Pick m to be larger than or equal to max(n) and a multiple of each entry in n
M = 1000
N = 20
m = 10^4
n = c(50,100,250,500,1000,5000,10000)

filename <- paste0(prefix,"gandk_optim_m",m,"_k",N,"_M",M,".RData")

t = proc.time()
mewe_gandk = foreach(rep = 1:M, .combine = rbind) %dorng% {

  #Allocate space for output
  mewe_store = matrix(0,length(n),target$thetadim)
  mewe_runtimes = rep(0,length(n))
  mewe_evals = rep(0,length(n))

  #generate all observations and sets of randomness to be used
  obs_rand = target$generate_randomness(max(n))
  obs_all = target$robservation(true_theta,obs_rand)

  #generate randomness for fake data
  sort_randomness = t(sapply(1:N, function(x) sort(target$generate_randomness(m))))

  for(i in 1:(length(n)) ){
    #Subset observations and sort
    obs = obs_all[1:n[i]]
    sort_obs = sort(obs)
    sort_obs_mult = rep(sort_obs, each = m/n[i])

    #Define the objective to be minimized to find the MEWE
    obj1 = function(theta){
      if(theta[1]<0.01 | theta[2]<0.01 | theta[3]<0.01 | theta[4]<0.01 | theta[1]>9.99 | theta[2]>9.99 | theta[3]>9.99 | theta[4]>9.99){
        out = 10^6
      } else{
        wass_dists = apply(sort_randomness, 1, function(x) metricL1(sort_obs_mult,target$robservation(theta,x)))
        out = mean(wass_dists)
      }
      return(out)
    }

    #Optimization
    t_mewe = proc.time()
    mewe = optim(true_theta,obj1)
    t_mewe = proc.time() - t_mewe

    #Save the results
    mewe_store[i,] = mewe$par
    mewe_runtimes[i] = t_mewe[3]
    mewe_evals[i] = mewe$counts[1]
  }

  #Output
  output = cbind(mewe_store,mewe_runtimes,mewe_evals,n,(1:length(n)))
  output
}
t = proc.time() - t
df.mewe = data.frame(mewe_gandk)
names(df.mewe) = c("A","B","g","k","runtime","fn.evals","n","gp")
save(df.mewe,t,file = filename)


# ################# Plots #################
load(filename)

df.mewe$A.scaled = (df.mewe$A - true_theta[1])*sqrt(df.mewe$n)
df.mewe$B.scaled = (df.mewe$B - true_theta[2])*sqrt(df.mewe$n)
df.mewe$g.scaled = (df.mewe$g - true_theta[3])*sqrt(df.mewe$n)
df.mewe$k.scaled = (df.mewe$k - true_theta[4])*sqrt(df.mewe$n)

gp.order = order(df.mewe$n)
df.mewe = df.mewe[gp.order,]


g <- ggplot(data = df.mewe, aes(x = A, y = B, colour = gp, group = gp)) #+ ylim(0, 1.5) + xlim(1,3)
g <- g + geom_point(alpha = 0.5)
g <- g +scale_colour_gradient2(midpoint = 4)
g <- g + xlab(expression(a)) + ylab(expression(b)) + theme(legend.position = "none")
g <- g + geom_vline(xintercept=true_theta[1]) + geom_hline(yintercept=true_theta[2])
g
ggsave(filename = paste0(prefix, "gandk_A_vs_B.png"), plot = g, width = 5, height = 5, dpi = 300)

g <- ggplot(data = df.mewe, aes(x = g, y = k, colour = gp, group = gp)) + ylim(0, 1.3) + xlim(0,7.5)
g <- g + geom_point(alpha = 0.5)
g <- g +scale_colour_gradient2(midpoint = 4)
g <- g + xlab(expression(g)) + ylab(expression(kappa)) + theme(legend.position = "none")
g <- g + geom_vline(xintercept=true_theta[3]) + geom_hline(yintercept=true_theta[4])
g
ggsave(filename = paste0(prefix, "gandk_g_vs_k.png"), plot = g, width = 5, height = 5, dpi = 300)


# g <- ggplot(data = df.mewe, aes(x = A.scaled, group = gp)) #+ ylim(0, 1.5) + xlim(1,3)
# g = g + scale_colour_gradient2(midpoint = 4)
# g = g + geom_density(aes(y=..density..), size = 1) + xlab(expression(B)) + theme(legend.position = "none")
# g
# #ggsave(filename = paste0(prefix, "gandk_rescaled_A.pdf"), plot = g, width = 7, height = 5)
#
# g <- ggplot(data = df.mewe, aes(x = B.scaled, group = gp)) #+ ylim(0, 1.5) + xlim(1,3)
# g = g + scale_colour_gradient2(midpoint = 4)
# g = g + geom_density(aes(y=..density..), size = 1) + xlab(expression(B)) + theme(legend.position = "none")
# g
# #ggsave(filename = paste0(prefix, "gandk_rescaled_B.pdf"), plot = g, width = 7, height = 5)
#
# g <- ggplot(data = df.mewe, aes(x = g.scaled, group = gp)) #+ ylim(0, 1.5) + xlim(1,3)
# g = g + scale_colour_gradient2(midpoint = 4)
# g = g + geom_density(aes(y=..density..), size = 1) + xlab(expression(g)) + theme(legend.position = "none")
# g
# #ggsave(filename = paste0(prefix, "gandk_rescaled_g.pdf"), plot = g, width = 7, height = 5)

g <- ggplot(data = df.mewe, aes(x = k.scaled, group = gp, color = gp)) #+ ylim(0, 1.5) + xlim(1,3)
g = g + scale_colour_gradient2(midpoint = 4)
g = g + geom_density(aes(y=..density..), size = 1) + xlab(expression(kappa)) + theme(legend.position = "none")
g
ggsave(filename = paste0(prefix, "gandk_rescaled_k.pdf"), plot = g, width = 5, height = 5)


#Histogram of observations
obs_for_hist = data.frame(observations = target$robservation(true_theta,target$generate_randomness(m)))
g = ggplot(obs_for_hist, aes(x = observations)) + geom_histogram(aes(y = ..density..))
g
ggsave(filename = paste0(prefix, "gandk_obs_hist.pdf"), plot = g, width = 5, height = 5)






