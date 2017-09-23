myindex=row.names(norm) %in% mygenes[,2]
myindex=which (myNA$NAs <=339) # filter based on values

myNA=rep(NA,length (colnames(datExprFemale)))
for (i in 1: length(rownames(endo_norm))){
  myNA[i]=mean(datExprFemale[,i])
}


datTraits=read.delim ("AVT_FC_vs_control_samples.txt", sep="\t", row.names=1)
data_FC=read.delim ("AVT_FC_vs_control.txt", sep="\t", row.names=1)
datExprFemale=t(data_FC)

A=adjacency(t(datExprFemale),type="distance") 
k=as.numeric(apply(A,2,sum))-1
Z.k=scale(k)
thresholdZ.k=-0.5
outlierColor=ifelse(Z.k<thresholdZ.k,"red","black")
sampleTree = flashClust(as.dist(1-A), method = "average")
datColors=data.frame(outlierC=outlierColor)
datColors=data.frame(outlierC=outlierColor, Tet=labels2colors(datTraits$Tetracycline), Pen=labels2colors(datTraits$Penicillins))

traitColors1=data.frame(numbers2colors(datTraits[,2]))
traitColors2=data.frame(labels2colors(datTraits[,1:4]))
datColors=data.frame(outlierC=outlierColor, traitColors2)
colnames(datColors)=c("Outlier", "Batch", "Serovar","Temp", "Phase")
colnames(traitColors2)=c("Media", "Stress", "H2O2_or_NO")

pdf ("Dendrogram_antibiotic__FC_0.1_filtered_rows.pdf", 100, 20)
plotDendroAndColors(sampleTree,groupLabels=names(datColors),colors=datColors,main="Sample dendrogram and trait heatmap")
dev.off()

plotDendroAndColors(sampleTree,groupLabels=names(traitColors2),colors=traitColors2,main="Sample dendrogram and trait heatmap")

remove.samples= Z.k<thresholdZ.k | is.na(Z.k)
datExprFemale_fil=datExprFemale[!remove.samples,]
datTraits_fil=datTraits[!remove.samples,]

A=adjacency(t(datExprFemale_fil),type="distance")
k=as.numeric(apply(A,2,sum))-1
Z.k=scale(k)

powers=c(1:30) 
sft=pickSoftThreshold(datExprFemale,powerVector=powers, networkType = "signed")

pdf("connectivity_plot_signed_30_All.pdf", 20, 20)
par(mfrow=c(1,2))
# SFT index as a function of different powers
plot(sft$fitIndices[,1],-sign(sft$fitIndices[,3])*sft$fitIndices[,2],
     xlab="Soft Threshold (power)",ylab="SFT, signed R^2",type="n",main=paste("Scale independence"))
text(sft$fitIndices[,1],-sign(sft$fitIndices[,3])*sft$fitIndices[,2],
     labels=powers,col="red")
# this line corresponds to using an R^2 cut-off of h
abline(h=0.90,col="red")
# Mean connectivity as a function of different powers
plot(sft$fitIndices[,1],sft$fitIndices[,5],type="n",
     xlab="Soft Threshold (power)",ylab="Mean Connectivity",main=paste("Mean connectivity"))
text(sft$fitIndices[,1],sft$fitIndices[,5],labels=powers,col="red")

dev.off()

mergingThresh = 0.25
net = blockwiseModules(datExprFemale,corType="pearson",
                       maxBlockSize=20000,networkType="signed",power=12,minModuleSize=20,
                       mergeCutHeight=mergingThresh,numericLabels=TRUE,saveTOMs=FALSE,
                       pamRespectsDendro=FALSE)



moduleLabelsAutomatic=net$colors
moduleColorsAutomatic = labels2colors(moduleLabelsAutomatic)
MEsAutomatic=net$MEs

barcode_diversity = as.data.frame(datTraits$Representative_OD)
names(barcode_diversity)="Representative_OD"
librarytype=as.numeric(cor(datExprFemale,datTraits$Library,use="p"))
complex_media=as.numeric(cor(datExprFemale,datTraits$Complex_media,use="p"))
centre=as.numeric(cor(datExprFemale,datTraits$Center,use="p"))
middle=as.numeric(cor(datExprFemale,datTraits$Middle,use="p"))
edge=as.numeric(cor(datExprFemale,datTraits$Edge,use="p"))
succinate=as.numeric(cor(datExprFemale,datTraits$Succinate,use="p"))
pyruvate=as.numeric(cor(datExprFemale,datTraits$Pyruvate,use="p"))
sorbitol=as.numeric(cor(datExprFemale,datTraits$Sorbitol,use="p"))

####################################calculate correlation and its signifcance
 
tetr=as.numeric(cor(datExprFemale_fil,datTraits_fil$Tetracycline,use="p"))
peni=as.numeric(cor(datExprFemale_fil,datTraits_fil$Penicillins,use="p"))
prot=as.numeric(cor(datExprFemale_fil,datTraits_fil$Protein_synthesis,use="p"))
cellwall=as.numeric(cor(datExprFemale_fil,datTraits_fil$Cell_wall_synthesis,use="p"))
dna=as.numeric(cor(datExprFemale_fil,datTraits_fil$DNA,use="p"))
membrane=as.numeric(cor(datExprFemale_fil,datTraits_fil$Cell_membrane,use="p"))
folate=as.numeric(cor(datExprFemale_fil,datTraits_fil$Folate.Synthesis,use="p"))
transcrip=as.numeric(cor(datExprFemale_fil,datTraits_fil$Transciption,use="p"))
chelator=as.numeric(cor(datExprFemale_fil,datTraits_fil$Chelator,use="p"))
cidal=as.numeric(cor(datExprFemale_fil,datTraits_fil$Cidal,use="p"))
static=as.numeric(cor(datExprFemale_fil,datTraits_fil$Static,use="p"))

myp=rep(NA,length (rownames(mytaudat)))
myr=rep(NA,length (rownames(mytaudat)))
for (i in 1:length (rownames(mytaudat)) ){
  
  mycor=cor.test(mytaudat[i,], mytau)
  myp[i]=mycor$p.value
  myr[i]=mycor$estimate
  }
myq = qvalue (myp)

tetrp=myq$qvalue
penip=myq$qvalue
protp=myq$qvalue
cellwallp=myq$qvalue
dnap=myq$qvalue
membranep=myq$qvalue
folatep=myq$qvalue
transcripp=myq$qvalue
chelatorp=myq$qvalue
cidalp=myq$qvalue
staticp=myq$qvalue



output=cbind(annotations[myindex,], tetr,peni,prot,cellwall,dna,membrane,folate,transcrip,chelator,cidal,static,tetrp,penip,protp,cellwallp,dnap,membranep,folatep,transcripp,chelatorp,cidalp,staticp, myfc[myindex,])  
write.table (output, sep="\t", "Antibiotic_correlations_lowess_FC.tab")

cormat=cbind(tetr,peni,prot,cellwall,dna,membrane,folate,transcrip,chelator,cidal)

librarytypeColor=numbers2colors(librarytype,signed=T)
complex_media_col=numbers2colors(complex_media,signed=T)
centre_col=numbers2colors(centre,signed=T)
middle_col=numbers2colors(middle,signed=T)
edge_col=numbers2colors(edge,signed=T)
succinate_col=numbers2colors(succinate,signed=T)
pyruvate_col=numbers2colors(pyruvate,signed=T)
sorbitol_col=numbers2colors(sorbitol,signed=T)

blocknumber=1
datColors=data.frame(moduleColorsAutomatic,librarytypeColor,complex_media_col,succinate_col,pyruvate_col,sorbitol_col, centre_col,middle_col,edge_col)[net$blockGenes[[blocknumber]],]

pdf("Gene_modules_signed_12_0.25.pdf", 50,25)
plotDendroAndColors(net$dendrograms[[blocknumber]],colors=datColors,
                    groupLabels=c("Module colors"),dendroLabels=FALSE,
                    hang=0.03,addGuide=TRUE,guideHang=0.05)

dev.off()

output=cbind ( rownames (mynorm), net$colors,librarytype,complex_media,succinate,pyruvate,sorbitol,centre,middle,edge)
write.table (output, "swim_modules_signed_20.tab", sep="\t")


MEList=moduleEigengenes(datExprFemale, colors=moduleLabelsAutomatic)
MEs = MEList$eigengenes
MET=orderMEs((cbind(MEs, datTraits$Library, datTraits$Complex_media, datTraits$Succinate, datTraits$Pyruvate, datTraits$Sorbitol, datTraits$Center, datTraits$Middle, datTraits$Edge )))

MET=orderMEs(cbind(MEs)
pdf("module_eigengenes_cluster_signed_10_0.25.pdf", 20, 20)
plotEigengeneNetworks(MET,"",marDendro=c(0,4,1,2),
                      marHeatmap=c(3,4,1,2),cex.lab=0.8,xLabelsAngle=90)
dev.off()



CAA=c(12:16,33:37, 54:58, 75:79)
CAA_LB=c(3,4,24,25,45,46,66,67)
GLU=c(7:11,28:32, 49:53, 70:74)
GLU_LB=c(1,2,22,23,43,44,64,65)
GLU_CAA=c(17:21,38:42,59:63,80:84)
GLU_CAA_LB=c(5,6,26,27,47,48,68,69)

CAA__400uMh2O2=glmLRT(fit, contrast =c(0,0,0,1,0,0,0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
CAA__5mMDETANONOate=glmLRT(fit, contrast =c(0,0,0,0,1,0,0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
CAA__5mMGSNO=glmLRT(fit, contrast =c(0,0,0,0,0,1,0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
CAA__5mMH2O2=glmLRT(fit, contrast =c(0,0,0,0,0,0,1,0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
CAA__750uMspermineNONOate=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,1,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
GLU__400uMh2O2=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,-1,0,0,0,0,0,0,0,0))
GLU__5mMDETANONOate=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,-1,0,0,0,0,0,0,0,0))
GLU__5mMGSNO=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,-1,0,0,0,0,0,0,0,0))
GLU__5mMH2O2=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,-1,0,0,0,0,0,0,0))
GLU__750uMspermineNONOate=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,-1,0,0,0,0,0,0,0,0))
GLU_CAA_400uMh2O2=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,-1,0))
GLU_CAA_5mMDETANONOate=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,-1,0))
GLU_CAA_5mMGSNO=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,-1,0))
GLU_CAA_5mMH2O2=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,-1))
GLU_CAA_750uMspermineNONOate=glmLRT(fit, contrast =c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,-1,0))

mycoef=read.delim ("coefs.txt", header=FALSE)






mycounts=estimateGLMCommonDisp(mycounts, mydesign)
mycounts=estimateGLMTrendedDisp(mycounts, mydesign)
mycounts=estimateGLMTagwiseDisp(mycounts, mydesign)
myfit=glmFit(mycounts, mydesign)


mycoef=(colnames(myfit))
for (i in 2:3)
{
  #assign (paste(coef[i,1]), glmLRT(fit, coef=i))
  #x=glmLRT(myfit, coef=i)
  x=glmLRT(fit, coef=i)
  de <- decideTestsDGE(x, p=0.1)
  detags <- rownames(data)[as.logical(de)]
  pdf (paste(mycoef[i],"_PBMC.pdf",sep=""))
  plotSmear (x, main=paste(mycoef[i],"_PBMC", sep=""), de.tags=detags)
  abline(h = c(-1,1), col = "blue")
  dev.off()
  write.table (topTags(x, n=nrow(data), sort.by = "none"),sep="\t", file=paste(mycoef[i],"_PBMC.fdr",sep="" ))
  remove (x)
  remove (de)
  remove (detags)
}

pdf("All_no_milk_Module_eigengenes_signed_19_0.25.pdf", 20,10)
for (i in 1:length(MEsAutomatic))
{
  plot (MEsAutomatic[,i], ylim=c(min(MEsAutomatic),max(MEsAutomatic)), xaxt='n', ylab="",xlab="",main=paste(colnames(MEsAutomatic[i])), pch=16, type="b")
  axis (1, at=c(1:length(rownames(MEsAutomatic))), labels=rownames(datExprFemale), las=2,par(mar=c(11,3,2,2)))
  
}
dev.off()  

write.table (cbind(colnames(datExprFemale),net$colors), "RNA_modules_signed_12_0.25.tab", sep="\t")
