require File.dirname(__FILE__)+'/trueskill_classes.rb'
require File.dirname(__FILE__)+'/gaussian.rb'


class Prediction

class << self 
 
def update(team1, team2, draw_probability, beta_squared, tau)

########### InItIaLIsE EMptY arraYs #############
team1_skills = Array.new(team1.length) {1}
team1_performances = Array.new(team1.length) {1}
team1_performances_new = Array.new(team1.length) {1}
team1_performances_update = Array.new(team1.length) {1}
team1_skills_update = Array.new(team1.length) {1}
team1_skills_new = Array.new(team1.length) {1}
team1_sum = Array.new(team1.length) {1}

team2_skills = Array.new(team2.length) {1}
team2_performances = Array.new(team2.length) {1}
team2_performances_new = Array.new(team2.length) {1}
team2_performances_update = Array.new(team2.length) {1}
team2_skills_update = Array.new(team2.length) {1}
team2_skills_new = Array.new(team2.length) {1}
team2_sum = Array.new(team2.length) {1}


eta = Distribution.inv_cdf(0.5*(1.0+draw_probability))*Math.sqrt((team1.length+team2.length)*beta_squared)

########### prIOr tO sKILLs LaYEr ############

team1.length.times do |i|
  team1_skills[i] = PriorToSkill.new(team1[i],tau)
end

team2.length.times do |i|
  team2_skills[i] = PriorToSkill.new(team2[i],tau)
end

########### sKILLs tO pErFOrManCE LaYEr ############

team1.length.times do |i|
  team1_performances[i] = SkillToPerformance.new(team1_skills[i],beta_squared,nil)
end

team2.length.times do |i|
  team2_performances[i] = SkillToPerformance.new(team2_skills[i],beta_squared,nil)
end

########### pErFOrManCE tO tEaMs LaYEr ############

home = NToOne.new(team1_sum, team1_performances)

away = NToOne.new(team2_sum, team2_performances)

########### tEaM DIFFErEnCEs, rEsuLt anD upDatE ############

a = [1,-1]
teamDiff = NToOne.new(a, [home, away])

return teamDiff.pam

end
end
end