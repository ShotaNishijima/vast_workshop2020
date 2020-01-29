
# 0. Prepare the data -------------------------------------------
dirname = "/Users/Yuki/Dropbox/vastws"
setwd(dir = dirname)

# Packages
require(TMB)
require(VAST)
require(tidyverse)

# read the data
df = read.csv("df.csv", fileEncoding = "CP932")
summary(df)
df = df %>% 
  filter(sakana == "C", between(year, 2022, 2026)) %>% 
  select(year, keido, ido, cpue, sakana) %>% 
  rename(lat = ido, lon = keido, spp = sakana) %>% mutate(time = paste(year, month, sep = "_"))
summary(df)


# 1. Settings ------------------------------------------------------
# 1.1 Version for cpp code
Version = get_latest_version(package = "VAST")

# 1.2 Spatial settings
Method = c("Grid", "Mesh", "Spherical_mesh")[2]
Kmeans_Config = list("randomseed" = 1, "nstart" = 100, "iter.max" = 1000)
grid_size_km = 25
n_x = 100

# 1.3 Model settings
FieldConfig = c(Omega1 = 1, Epsilon1 = 1, Omega2 = 1, Epsilon2 = 1) #factor analysis
RhoConfig = c(Beta1 = 0, Beta2 = 0, Epsilon1 = 0, Epsilon2 = 0) #0: fixed, 1: independent, 2:RW, 3:constant, 4:AR
OverdispersionConfig = c("Eta1" = 1, "Eta2" = 1) #overdispersion
ObsModel = c(PosDist = 2, Link = 0)
Options = c(SD_site_density = 0, SD_site_logdensity = 0,
            Calculate_Range = 1, Calculate_evenness = 0, 
            Calculate_effective_area = 1, Calculate_Cov_SE = 0, 
            Calculate_Synchrony = 0, Calculate_Coherence = 0)

# 1.4 Stratification for results
strata.limits = data.frame('STRATA'="All_areas")

# 1.5 Derived objects
Region = "others"

# 1.6 Save settings
DateFile = paste0(getwd(),'/sakanaC_od/')
dir.create(DateFile)
Record = list(Version = Version, Method = Method, grid_size_km = grid_size_km, n_x = n_x, 
              FieldConfig = FieldConfig, RhoConfig = RhoConfig, OverdispersionConfig = OverdispersionConfig, 
              ObsModel = ObsModel, Kmeans_Config = Kmeans_Config, Region = Region,
              strata.limits = strata.limits) 
setwd(dir = DateFile)
save(Record, file = file.path(DateFile, "Record.RData")) 
capture.output(Record, file = paste0(DateFile, "/Record.txt"))


# 2. Prepare the data ----------------------------------------------
# 2.1 Data-frame
head(df)
Data_Geostat = df %>% select(year, lon, lat, cpue, time) %>% mutate(Year = year, Lon = lon, Lat = lat, Catch_KG = cpue, Time = time)

# 2.2 Extrapolation grid
Extrapolation_List = FishStatsUtils::make_extrapolation_info(
  Regio = Region, #zone range in Japan is 51:56
  strata.limits = strata.limits, 
  observations_LL = Data_Geostat[, c("Lat", "Lon")]
)

# 2.3 derived objects for spatio-temporal estimation
Spatial_List = FishStatsUtils::make_spatial_info(
  n_x = n_x,
  Lon = Data_Geostat[, "Lon"], 
  Lat = Data_Geostat[, "Lat"], 
  Extrapolation_List = Extrapolation_List, 
  Method = Method,
  grid_size_km = grid_size_km,
  randomseed = Kmeans_Config[["randomseed"]], 
  nstart = Kmeans_Config[["nstart"]], 
  iter.max = Kmeans_Config[["iter.max"]], 
  #fine_scale = TRUE,
  DirPath = DateFile,
  Save_Results = TRUE)

# 2.4 save Data_Geostat
Data_Geostat = cbind(Data_Geostat, knot_i = Spatial_List[["knot_i"]], zone = Extrapolation_List[["zone"]])
write.csv(Data_Geostat, "Data_Geostat.csv")


# 3. Build and run model ----------------------------------------
TmbData = make_data(
  Version = Version,
  FieldConfig = FieldConfig, 
  OverdispersionConfig = OverdispersionConfig, 
  RhoConfig = RhoConfig, 
  ObsModel = ObsModel, 
  c_iz = rep(0, nrow(Data_Geostat)), 
  b_i = Data_Geostat[, 'Catch_KG'], 
  a_i = rep(1, nrow(Data_Geostat)), #cpue
  #a_i = Data_Geostat[, 'AreaSwept_km2'], # catch and effort
  s_i = Data_Geostat[, 'knot_i'] - 1,
  t_i = Data_Geostat[, 'Year'], 
  v_i = matrix(Data_Geostat[, "Time"]),
  spatial_list = Spatial_List, 
  Options = Options,
  Aniso = TRUE
)

TmbList = VAST::make_model(TmbData = TmbData,
                           RunDir = DateFile,
                           Version = Version,
                           RhoConfig = RhoConfig,
                           loc_x = Spatial_List$loc_x,
                           Method = Spatial_List$Method)

Obj = TmbList[["Obj"]]
Opt = TMBhelper::fit_tmb(obj = Obj, 
                         lower = TmbList[["Lower"]], 
                         upper = TmbList[["Upper"]],
                         getsd = TRUE, 
                         savedir = DateFile, 
                         bias.correct = TRUE)

Report = Obj$report()
Save = list("Opt" = Opt, 
            "Report" = Report, 
            "ParHat" = Obj$env$parList(Opt$par),
            "TmbData" = TmbData)
save(Save, file = paste0(DateFile,"/Save.RData"))

# 4. Figures -------------------------------------------------------
# 4.1 Plot data
plot_data(Extrapolation_List = Extrapolation_List, Spatial_List = Spatial_List, Data_Geostat = Data_Geostat, PlotDir = DateFile)

# 4.2 Convergence
pander::pandoc.table(Opt$diagnostics[, c('Param','Lower','MLE','Upper','final_gradient')])

# 4.3 Diagnostics for encounter-probability component
Enc_prob = plot_encounter_diagnostic(Report = Report, Data_Geostat = Data_Geostat, DirName = DateFile)

# 4.4 Diagnostics for positive-catch-rate component
Q = plot_quantile_diagnostic(TmbData = TmbData, 
                             Report = Report, 
                             FileName_PP = "Posterior_Predictive",
                             FileName_Phist = "Posterior_Predictive-Histogram", 
                             FileName_QQ = "Q-Q_plot", 
                             FileName_Qhist = "Q-Q_hist", 
                             DateFile = DateFile )

# 4.5 Diagnostics for plotting residuals on a map
MapDetails_List = make_map_info("Region" = Region, 
                                "spatial_list" = Spatial_List, 
                                "Extrapolation_List" = Extrapolation_List)
Year_Set = seq(min(Data_Geostat[,'Year']), max(Data_Geostat[,'Year']))
Years2Include = which(Year_Set %in% sort(unique(Data_Geostat[,'Year'])))

plot_residuals(Lat_i = Data_Geostat[,'Lat'], 
               Lon_i = Data_Geostat[,'Lon'], 
               TmbData = TmbData, 
               Report = Report, 
               Q = Q, 
               savedir = DateFile, 
               spatial_list = Spatial_List, #
               extrapolation_list = Extrapolation_List, #
               MappingDetails = MapDetails_List[["MappingDetails"]], 
               PlotDF = MapDetails_List[["PlotDF"]], 
               MapSizeRatio = MapDetails_List[["MapSizeRatio"]], 
               Xlim = MapDetails_List[["Xlim"]], 
               Ylim = MapDetails_List[["Ylim"]], 
               FileName = DateFile, 
               Year_Set = Year_Set, 
               Years2Include = Years2Include, 
               Rotate = MapDetails_List[["Rotate"]], 
               Cex = MapDetails_List[["Cex"]], 
               Legend = MapDetails_List[["Legend"]], 
               zone = MapDetails_List[["Zone"]], 
               mar = c(0,0,2,0), 
               oma = c(3.5,3.5,0,0), 
               cex = 1.8)

# 4.6 Direction of "geometric anisotropy"
plot_anisotropy(FileName = paste0(DateFile,"Aniso.png"), 
                Report = Report, 
                TmbData = TmbData)

# 4.7 Density surface for each year
Dens_xt = plot_maps(plot_set = c(3), 
                    MappingDetails = MapDetails_List[["MappingDetails"]], 
                    Report = Report, 
                    Sdreport = Opt$SD, 
                    PlotDF = MapDetails_List[["PlotDF"]], 
                    MapSizeRatio = MapDetails_List[["MapSizeRatio"]], 
                    Xlim = MapDetails_List[["Xlim"]], 
                    Ylim = MapDetails_List[["Ylim"]], 
                    FileName = DateFile, 
                    Year_Set = Year_Set, 
                    Years2Include = Years2Include, 
                    Rotate = MapDetails_List[["Rotate"]],
                    Cex = MapDetails_List[["Cex"]], 
                    Legend = MapDetails_List[["Legend"]], 
                    zone = MapDetails_List[["Zone"]], 
                    mar = c(0,0,2,0), 
                    oma = c(3.5,3.5,0,0), 
                    cex = 1.8, 
                    plot_legend_fig = FALSE)

Dens_DF = cbind("Density" = as.vector(Dens_xt), 
                "Year" = Year_Set[col(Dens_xt)], 
                "E_km" = Spatial_List$MeshList$loc_x[row(Dens_xt),'E_km'], 
                "N_km" = Spatial_List$MeshList$loc_x[row(Dens_xt),'N_km'])

pander::pandoc.table(Dens_DF[1:6,], digits=3)

# 4.8 Index of abundance
Index = plot_biomass_index(DirName = DateFile, 
                           TmbData = TmbData, 
                           Sdreport = Opt[["SD"]], 
                           Year_Set = Year_Set, 
                           Years2Include = Years2Include, 
                           use_biascorr=TRUE )
pander::pandoc.table(Index$Table[,c("Year","Fleet","Estimate_metric_tons","SD_log","SD_mt")] ) 

# 4.9 Center of gravity and range expansion/contraction
plot_range_index(Report = Report, 
                 TmbData = TmbData, 
                 Sdreport = Opt[["SD"]], 
                 Znames = colnames(TmbData$Z_xm), 
                 PlotDir = DateFile, 
                 Year_Set = Year_Set)

# 4.10 Plot overdispersion
FishStatsUtils::plot_overdispersion(filename1 = paste0("Overdispersion"),
                                    filename2 = paste0("Overdispersion--panel"),
                                    Data = TmbData,
                                    ParHat = Save[["ParHat"]],
                                    Report = Report,
                                    ControlList1 = list(Width = 5, Height = 10,
                                                        Res = 200, Units = "in"),
                                    ControlList2 = list(Width = TmbData$n_c,
                                                        Height = TmbData$n_c,
                                                        Res = 200, Units = "in"))
