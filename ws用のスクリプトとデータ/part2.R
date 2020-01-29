
# 0. setting ----------------------------------------------------
#if needed
# インストールする際に色々なパッケージをアップデートするか聞かれるが，3(None)でよい
# require(devtools)
# install_github("Yuki-Kanamori/ggvast")

require(tidyverse)
require(ggvast)

# 0.1 set the directory ---------------------------------------------
vast_output_dirname = "/Users/Yuki/Dropbox/vastws/multisp2"
fig_output_dirname = "/Users/Yuki/Dropbox/vastws/ggvast"
setwd(dir = vast_output_dirname)

# 0.2 load the data -------------------------------------------------
load("Save.RData")
DG = read.csv("Data_Geostat.csv")

# 1. plot index ------------------------------------------------
# vast output
setwd(dir = vast_output_dirname)
vast_index = read.csv("Table_for_SS3.csv") %>% mutate(type = "Standardized")

# nominal
levels(DG$spp) #単一種の時はNULLと出る
category_name = c("x", "y", "z") #カテゴリーの名前（魚種名や銘柄など）

# vastの結果が複数ある場合
setwd(dir = ////)
vast_index2 = read.csv("Table_for_SS3.csv") %>% mutate(type = "Standardized2") #typeの名前は適宜変更
vast_index = rbind(vast_index, vast_index2)

# make a figure
# nominalにはerror barが無いため，geom_errorbarのwarningが出るが問題ない
plot_index(vast_index = vast_index,
           DG = DG,
           category_name = category_name,
           fig_output_dirname = fig_output_dirname)



# 2. get dens --------------------------------------------------
# make a data-frame
df_dens = get_dens(category_name = category_name)


# 3. map dens ---------------------------------------------------
#DG2 = DG %>% filter(Catch_KG > 0) #> 0データのみをプロットしたい場合

data = df_dens #VASTの時
#data = DG #ノミナルの時
#data = DG2 #ノミナル>0の時

#require(maps)
#unique(map_data("world")$region)
region = "Japan" #作図する地域を選ぶ
scale_name = "Log density" #凡例　色の違いが何を表しているのかを書く
ncol = 2 #横にいくつ図を並べるか（最大数 = 年数）
shape = 16 #16はclosed dot
size = 1.9 #shapeの大きさ

# make figures
map_dens(data = data,
         region = region,
         scale_name = scale_name,
         ncol = ncol,
         shape = shape,
         size = size,
         fig_output_dirname =  fig_output_dirname)



# 4. get cog ----------------------------------------------------
# make a data-frame
cog_nom = get_cog(data = DG)



# 5. map COG ----------------------------------------------------
data_type = c("VAST", "nominal")[1]

#unique(map_data("world")$region)
region = "Japan" #作図する地域を選ぶ
ncol = 2 #横にいくつ図を並べるか（最大数 = カテゴリー数）
shape = 16 #16はclosed dot
size = 1.9 #shapeの大きさ
use_biascorr = TRUE

# make figures
map_cog(data_type = data_type,
        category_name = category_name,
        region = region,
        ncol = ncol,
        shape = shape,
        size = size,
        fig_output_dirname = fig_output_dirname)
