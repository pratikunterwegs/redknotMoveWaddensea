#### link patch size to exploration score ####

# load libs
library(tidyr); library(dplyr); library(readr); library(sf)

# read in patch size data from shapefile
patches <- st_read("../data2018/oneHertzDataSubset/patches.json")

# read in behav scores
behavScore <- read_csv("../data2018/behavScores.csv") %>% 
  mutate(bird = factor(id))

# link behav score and patch size and area
patches <- left_join(patches, behavScore, by= c("bird")) %>% 
  st_drop_geometry()

# # filter out unreasonable data of greater than 100 x 100 m
# patches <- filter(patches)

# make exploratory plots
library(ggplot2)
source("codePlotOptions/geomFlatViolin.r")
source("codePlotOptions/ggThemePub.r")

#### patch area vs tidal stage over season ####
# plot boxplots of foraging vs non-foraging patches
patches %>% 
  mutate(highTideHour = floor(tidaltime_mean/60),
         foraging = ifelse(between(highTideHour, 4, 9), "low-tide", "high-tide")) %>%
  ggplot()+
  geom_boxplot(aes(x = factor(highTideHour), 
                   y = area, fill = highTideHour %in% c(4:9)),
               position = position_dodge(preserve = "single", width = 1))+
  facet_wrap(~tidalCycle)+
  scale_fill_brewer(palette = "Accent", label = c("high tide","low tide"))+
  themePubLeg()+
  ylim(0,1e4)+
  labs(x = "hours since high tide", y = bquote("patch area" (m^2)),
       title = "patch area ~ time since high tide",
       caption = Sys.time(), fill = "rough tidal stage")+
  theme(legend.position = c(0.9, 0.1))

ggsave(filename = "../figs/figPatchAreaVsTime.pdf", width = 11, height = 8,
       device = pdf()); dev.off()

#### patch count plot ####
patches %>% 
  mutate(highTideHour = floor(tidaltime_mean/60),
         foraging = ifelse(between(highTideHour, 4, 9), "low-tide", "high-tide")) %>%
  count(bird, highTideHour, name = "nPatches") %>% 
  
  ggplot()+
  geom_flat_violin(aes(x = factor(highTideHour), y = nPatches, 
                       fill = highTideHour %in% c(4:9)),
                   col = "transparent",
                   position = position_nudge(x = .1, y = 0),
                   scale = "width")+
  geom_boxplot(aes(x = factor(highTideHour), 
                   y = nPatches, col = highTideHour %in% c(4:9)),
               position = position_nudge(x = -.1, y = 0),
               width = 0.2,
               size = 0.5,
               outlier.colour = stdGry, outlier.size = 0.5)+
  #facet_wrap(~tidalCycle)+
  scale_fill_brewer(palette = "Accent", label = c("high tide","low tide"))+
  scale_colour_brewer(palette = "Accent", label = c("high tide","low tide"))+
  themePubLeg()+
  #ylim(0,1e4)+
  labs(x = "hours since high tide", y = "# patches",
       title = "number of patches ~ time since high tide",
       caption = Sys.time(), fill = "rough tidal stage", colour = "rough tidal stage")+
  theme(legend.position = c(0.9, 0.9))

ggsave(filename = "../figs/figPatchNumberVsTidalTime.pdf", width = 6, height = 5,
       device = pdf()); dev.off()

#### patch distance plot ####
patches %>% 
  mutate(highTideHour = floor(tidaltime_mean/60),
         foraging = ifelse(between(highTideHour, 4, 9), "low-tide", "high-tide")) %>%
  
  ggplot()+
  geom_flat_violin(aes(x = factor(highTideHour), y = dist, fill = foraging),
                   col = "transparent",
                   position = position_nudge(x = .1, y = 0),
                   scale = "width")+
  geom_boxplot(aes(x = factor(highTideHour), y = dist, col = foraging), 
               position = position_nudge(x = -.1, y = 0), 
               width = 0.2,
               size = 0.3,
               outlier.colour = stdGry, outlier.size = 0.5)+
  facet_wrap(~tidalCycle)+
  labs(x = "hours since high tide", y = "distance between patches (m)",
       caption = Sys.time(), title = "inter-patch distance ~ tidal time",
       fill = "rough tidal stage", colour = "rough tidal stage")+
  ylim(0, 2e3)+
  
  scale_fill_brewer(palette = "Accent", label = c("high tide","low tide"))+
  scale_colour_brewer(palette = "Accent", label = c("high tide","low tide"))+
  themePubLeg()+
  theme(legend.position = c(0.9, 0.1))

ggsave(filename = "../figs/figPatchDistanceVsTime.pdf", width = 11, height = 8,
       device = pdf()); dev.off()

# plot patch area vs other predictors
patches %>% #filter(area < 1e5) %>% 
  as_tibble() %>% 
  select(area, WING, MASS, gizzard_mass, pectoral, exploreScore, bird, tidalCycle) %>% 
  gather(predictor, value, -bird, -area, -tidalCycle) %>% 

ggplot()+
  geom_jitter(aes(x = value, y = area, group = bird), size= 0.1, alpha = 0.2)+
  geom_smooth(aes(x = value, y = area), method = "glm")+
  facet_grid(tidalCycle~predictor, scales = "free_x")+
  coord_cartesian(ylim = c(0,1e4))+
  labs(x = "predictor value", y = "patch area (m^2)", caption = Sys.time(),
       title = "patch area ~ various predictors")+
  themePub()

ggsave(filename = "../figs/figPatchAreaVsPredictors.pdf", width = 11, height = 8,
       device = pdf()); dev.off()

# write patch metrics to file later




count(patches, bird, tidalCycle, name = "nPatches") %>% 
  left_join(behavScore) %>% 
  
  select(nPatches, WING, MASS, gizzard_mass, pectoral, exploreScore, bird, tidalCycle) %>% 
  gather(predictor, value, -bird, -nPatches, -tidalCycle) %>% 
  
  ggplot()+
  geom_jitter(aes(x = value, y = nPatches))+
  facet_grid(tidalCycle~predictor, scales = "free_x")
