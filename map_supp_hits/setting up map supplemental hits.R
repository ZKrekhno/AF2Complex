


library(clipr)
library(tidyverse)
library(readxl)


#Import mitocarta objet and the interacting partners for ACAT1 = P24752, LRPPRC = P42704, VDAc2 = P45880

#Import mitocarta data
cart <- read_excel(here::here("map_supp_hits/Human.MitoCarta3.0.xls"), sheet = 2)
#Import intact files
intact_files <- list.files(path = here::here(), pattern = "intact.tsv", recursive = T)
intact_list <- intact_files %>% 
  map(~read_tsv(here::here(.x)))
#Organize intact objects for ease of use 
intact_dfs <- intact_list %>% 
  reduce(bind_rows) %>% 
  select(A = `# ID(s) interactor A`,B =  `ID(s) interactor B`,Alias_A = `Alias(es) interactor A`, Alias_B = `Alias(es) interactor B`) %>% 
  filter(if_all(.cols = c(A,B), .fns = ~str_detect(.x, "uniprotkb"))) %>% 
  mutate(A = str_remove(A, "uniprotkb:"),
         B = str_remove(B, "uniprotkb:"))
#Rearrange the table so that all A are my hits of interest, and all B are other proteins
dfs <- intact_dfs %>% 
  filter(A %in% c("P24752","P42704", "P45880")) %>% 
  bind_rows(.,rename(filter(intact_dfs, B %in% c("P24752","P42704", "P45880")),
                     B = A,
                     A = B)) %>% 
  distinct(A,B, .keep_all = T)
#Add mitocarta information to the dfs object
annot_dfs <- cart %>% 
  select(Symbol, Description, UniProt, ProteinLength) %>% 
  inner_join(dfs, by = c("UniProt" = "B")) %>% 
  filter(ProteinLength < 350)

  







