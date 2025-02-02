library("ggplot2")
library(patchwork)
library(ggpubr)
require(cowplot)
library(gridExtra)
library(grid)
library(corrplot)
library(Hmisc)
library(PerformanceAnalytics)
library(WGCNA)
library(reshape2)
traits <- read.csv('../raw data/traits.csv', header = T, row.names=1) 
sal_ph_alk <- read.csv('../raw data/sal_ph_alk.csv', header = T, row.names=1) 

#figs-----
sal=sal_ph_alk[,1:5]
sal$time = c(1:49)
sal_mydata = melt(sal, id = "time")

p1=ggplot(data = sal_mydata,aes(x =time, y =value,group = variable,
                             color = variable,
                             shape = variable)) + 
  geom_point()+theme_classic()+ coord_cartesian(ylim = c(32,34))
#-------
pH=sal_ph_alk[,6:10]
pH$time = c(1:49)
pH_mydata = melt(pH, id = "time")
p2=ggplot(data = pH_mydata,aes(x =time, y =value,group = variable,
                             color = variable,
                             shape = variable)) + 
  geom_point()+theme_classic()+ coord_cartesian(ylim = c(7,8.5))
#-------
alk=sal_ph_alk[,11:15]
alk$time = c(1:49)
alk_mydata = melt(alk, id = "time")
p3=ggplot(data = alk_mydata,aes(x =time, y =value,group = variable,
                            color = variable,
                            shape = variable)) + 
  geom_point()+theme_classic()+ coord_cartesian(ylim = c(2000,2800))

pdf("time_series.pdf",width=16,height=3) 
grid.newpage()
pushViewport(viewport(layout = grid.layout(1,3)))
print(p1, vp = viewport(layout.pos.row = 1, layout.pos.col = 1))
print(p2, vp = viewport(layout.pos.row = 1, layout.pos.col = 2))
print(p3, vp = viewport(layout.pos.row = 1, layout.pos.col = 3))

dev.off() 

#FIG1c----
conditionshg <- factor(c(rep("Control",4),rep( "Ca(OH)2",4),rep("CO2",4),rep("CO2+Ca(OH)2",4),rep("CO2+NaOH",4)))


plot_list = list() 
compaired <- list(c("Control", "Ca(OH)2"), 
                  c("Control","CO2"), 
                  c("Control","CO2+Ca(OH)2"),
                  c("Control","CO2+NaOH"))
for (i in 1:9) {
  data_cor <- traits[, i]
  hgdata_treat_cor <- data.frame(conditionshg, data_cor)
  hgdata_treat_cor$conditionshg <- factor(conditionshg, level = c("Control", "Ca(OH)2", "CO2", "CO2+Ca(OH)2", "CO2+NaOH"), ordered = TRUE)
  
  # 添加y轴标签
  y_label <- names(traits)[i]
  
  p <- ggplot(hgdata_treat_cor, aes(conditionshg, data_cor, color = conditionshg)) +
    geom_boxplot() +
    geom_point(size = 2) +
    theme_classic() +
    geom_signif(comparisons = compaired, step_increase = 0.1, map_signif_level = T, test = t.test) +
    labs(y = y_label) +  # 设置标题和y轴标签
    theme(legend.position = "none", axis.title.x = element_blank(), axis.text.x = element_text(angle = 30, hjust = 1))
  
  plot_list[[i]] = p
}

##fig 1

 
grid.arrange(plot_list[[1]], plot_list[[2]], plot_list[[3]],
             plot_list[[4]], plot_list[[5]], plot_list[[6]],
             plot_list[[7]], plot_list[[8]], plot_list[[9]],
             ncol = 3) 
#melt---
library(tidyr)
library(reshape2)
traits1 <-cbind(traits,data.frame(conditionshg))
mydata<-melt(traits1,                       #待转换的数据集名称
             id.vars=c("conditionshg"),  #要保留的主字段
             variable.name="Group",         #转换后的分类字段名称（维度）
             value.name="value"             #转换后的度量值名称
)
mydata$conditionshg <- factor(conditionshg, level=c("Control", "Ca(OH)2","CO2","CO2+Ca(OH)2","CO2+NaOH"), ordered=TRUE)
pdf("traits_plots_wrap.pdf",width=8,height=6) 
mydata %>%  
ggplot(aes(conditionshg,value),ordered=T)+
  geom_boxplot(color='blue')+
  facet_wrap(~Group, scales = "free",nrow=3,strip.position="left",shrink=T)+
  theme_classic() + 
  theme(axis.text.x = element_text(angle = 30, hjust = 0.5, vjust = 0.5))+
 geom_signif(comparisons = compaired,step_increase = 0.2,map_signif_level = T,test = t.test)+
 theme(panel.background = element_rect(fill = "transparent",colour = NA), panel.grid.minor = element_blank(), plot.background = element_rect(fill = "transparent",colour = NA),strip.background = element_blank(), strip.placement = "outside")
dev.off() 

#plot PCA----------------------
# install.packages("devtools")
# devtools::install_github("factoextra")
library(factoextra)
citation("factoextra")
traits.pca <- prcomp(traits[,1:9], scale. = TRUE)

p10<- fviz_pca_var(traits.pca ,col.var = "contrib",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"))+
  theme_classic()
ggsave("p10.pdf", p10, width=12, height=20)
library(patchwork)
# Arrange the plots using patchwork
p11<- (plot_list[[1]] + plot_list[[2]] + plot_list[[3]])/
    (plot_list[[4]] + plot_list[[5]] + plot_list[[6]])/
    (plot_list[[7]] + plot_list[[8]] + plot_list[[9]])  
ggsave("tratis.pca.pdf", p11,width=7, height=10)
#anova analysis----------------------
traits$con <-conditionshg
result <- aov(CO2 ~ con, data = traits)
library(multcomp)
# 进行Tukey多重比较
comp <- glht(result, linfct = mcp(con = "Tukey"))
# 查看ANOVA分析结果
summary(result)
summary(comp) 
 
# Plot the sample tree: Open a graphic output window of size 12 by 9 inches
# The user should change the dimensions if the window is too large or too small.
#pdf(file = "Plots/sampleClustering.pdf", width = 12, height = 9);sizeGrWindow(12,9)
# sampleTree = hclust(dist(t(traits)), method = "median");
# 
# plot(sampleTree, main = "Sample clustering to detect outliers", sub="", xlab="", cex.lab = 1.5, 
#      cex.axis = 1.5, cex.main = 2)
# ## bioplot
# ggbiplot(traits.pca,groups = colnames(traits), ellipse = TRUE, circle = TRUE) 
# 
# pdf("normalized.gene.pca.pdf", width=6, height=3)
# theme_set(theme_classic())
# autoplot(object = pam(cleandata_g, 4), frame = TRUE, frame.type = 'norm') +theme(axis.text=element_text(size=12),legend.title = element_blank())
# dev.off()