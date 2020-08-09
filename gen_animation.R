filePath = dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(filePath)

library(magick)

# cases_file_list <- list.files(path = "./plots/cases/", pattern = "*.jpg", full.names = T)
# mcimg <- image_read(cases_file_list)
# mcimg <- image_animate(mcimg, fps = 10, loop = 1, optimize = TRUE)
# image_write(mcimg, "anim_cases.gif")

# deaths_file_list <- list.files(path = "./plots/deaths/", pattern = "*.jpg", full.names = T)
# mdimg <- image_read(deaths_file_list)
# mdimg <- image_animate(mdimg, fps = 10, loop = 1, optimize = TRUE)
# image_write(mdimg, "anim_deaths.gif")

# case_pcts_file_list <- list.files(path = "./plots/case_pcts/", pattern = "*.jpg", full.names = T)
# mcimg <- image_read(case_pcts_file_list)
# mcimg <- image_animate(mcimg, fps = 10, loop = 1, optimize = TRUE)
# image_write(mcimg, "anim_case_pcts.gif")

death_pcts_file_list <- list.files(path = "./plots/death_pcts/", pattern = "*.jpg", full.names = T)
mdimg <- image_read(death_pcts_file_list)
mdimg <- image_animate(mdimg, fps = 10, loop = 1, optimize = TRUE)
image_write(mdimg, "anim_death_pcts.gif")
