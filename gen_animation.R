setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magick)

# cases_file_list <- list.files(path = "./plots/cases/", pattern = "*.jpg", full.names = T)
# mcimg <- image_read(cases_file_list)
# mcimg <- image_animate(mcimg, fps = 5, loop = 1, optimize = TRUE)
# image_write(mcimg, "anim_cases.gif")

# deaths_file_list <- list.files(path = "./plots/deaths/", pattern = "*.jpg", full.names = T)
# mdimg <- image_read(deaths_file_list)
# mdimg <- image_animate(mdimg, fps = 5, loop = 1, optimize = TRUE)
# image_write(mdimg, "anim_deaths.gif")

# cases_file_list <- list.files(path = "./plots/case_pcts/", pattern = "*.jpg", full.names = T)
# mcimg <- image_read(cases_file_list)
# mcimg <- image_animate(mcimg, fps = 5, loop = 1, optimize = TRUE)
# image_write(mcimg, "anim_case_pcts.gif")

deaths_file_list <- list.files(path = "./plots/death_pcts/", pattern = "*.jpg", full.names = T)
mdimg <- image_read(deaths_file_list)
mdimg <- image_animate(mdimg, fps = 5, loop = 1, optimize = TRUE)
image_write(mdimg, "anim_death_pcts.gif")
