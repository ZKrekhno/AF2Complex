#Try doing the next step in R on the server
R
#choose newest version by clicking 1
install.packages("tidyverse", repos='https://cloud.r-project.org/')
library(tidyverse)
intact_df <- read_tsv("intact/intact_whole.txt")
dummy_df <- intact_df [,c(1,2)]
colnames(dummy_df) <- c("A","B")
intact_dfs <- dummy_df %>% 
  filter(if_all(.cols = c(A,B), .fns = ~str_detect(.x, "uniprotkb"))) %>% 
  mutate(A = str_remove(A, "uniprotkb:"),
         B = str_remove(B, "uniprotkb:"))
dfs <- intact_dfs %>% 
  filter(A %in% c('P04181',	'P07437',	'P10515',	'P10809',	'P24752',	'P30048',	'P36957',	'P38646',	'P49411',	'P68104',	'P68363',	'Q6UB35',	'Q9NSE4',	'Q9NVI7',	'Q9Y2Z4')) %>% 
  bind_rows(.,rename(filter(intact_dfs, B %in% c('P04181',	'P07437',	'P10515',	'P10809',	'P24752',	'P30048',	'P36957',	'P38646',	'P49411',	'P68104',	'P68363',	'Q6UB35',	'Q9NSE4',	'Q9NVI7',	'Q9Y2Z4')),
                     B = A,
                     A = B)) %>% 
  distinct(A,B, .keep_all = T)
write_csv(dfs,"APEX_hits_Intact_extract.csv")