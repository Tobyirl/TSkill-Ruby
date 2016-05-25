require File.dirname(__FILE__)+'/trueskill_classes.rb'
require File.dirname(__FILE__)+'/gaussian.rb'


class Skills

	class << self 
 
		def update(team1, team2, draw_probability, beta_squared, tau, win_draw, team1_old_update, team2_old_update)

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
			  if team1_old_update == nil
				  team1_performances[i] = SkillToPerformance.new(team1_skills[i],beta_squared,nil)
			  else
				  team1_performances[i] = SkillToPerformance.new(team1_skills[i],beta_squared,team1_old_update[i])
			  end
			end

			team2.length.times do |i|
			  if team2_old_update == nil
				  team2_performances[i] = SkillToPerformance.new(team2_skills[i],beta_squared,nil)
			  else
				  team2_performances[i] = SkillToPerformance.new(team2_skills[i],beta_squared,team2_old_update[i])
			  end
			end

			########### pErFOrManCE tO tEaMs LaYEr ############

			home = NToOne.new(team1_sum, team1_performances)

			away = NToOne.new(team2_sum, team2_performances)

			########### tEaM DIFFErEnCEs, rEsuLt anD upDatE ############

			if win_draw == 1
				a = [1, -1]
				teamDiff = NToOne.new(a, [home, away])
				result = ResultWin.new(teamDiff, eta)
			elsif win_draw == -1
				a = [-1, 1]
				teamDiff = NToOne.new(a, [home, away])
				result = ResultWin.new(teamDiff, eta)
			else win_draw == 0
				a = [1, -1]
				teamDiff = NToOne.new(a, [home, away])
				result = ResultDraw.new(teamDiff, eta)
			end

			all_nodes = [home, away]
			vector_a = a
			precision_array = vector_a.zip(all_nodes).map {|a, nodes| (a**2)*(nodes.field_time**2)/nodes.precision}
			pam_array = vector_a.zip(all_nodes).map {|a, nodes| a*(nodes.field_time*nodes.pam)/nodes.precision}

			home_update = OneToN.new(teamDiff,result,[home,away],vector_a,precision_array,pam_array,0)
			away_update = OneToN.new(teamDiff,result,[home,away],vector_a,precision_array,pam_array,1)

			home_new = SumMessages.new(home,home_update,nil)
			away_new = SumMessages.new(away,away_update,nil)

			########### tEaMs tO pErFOrManCEs ############

			all_nodes = team1_performances
			vector_a = team1_sum
			precision_array = vector_a.zip(all_nodes).map {|a, nodes| (a**2)*(nodes.field_time**2)/nodes.precision}
			pam_array = vector_a.zip(all_nodes).map {|a, nodes| a*(nodes.field_time*nodes.pam)/nodes.precision}

			team1.length.times do |i|
			  team1_performances_update[i] = OneToN.new(home,home_new,all_nodes,vector_a,precision_array,pam_array,i)
			  team1_performances_new[i] = SumMessages.new(team1_performances[i], team1_performances_update[i],nil)
			end

			all_nodes = team2_performances
			vector_a = team2_sum
			precision_array = vector_a.zip(all_nodes).map {|a, nodes| (a**2)*(nodes.field_time**2)/nodes.precision}
			pam_array = vector_a.zip(all_nodes).map {|a, nodes| a*(nodes.field_time*nodes.pam)/nodes.precision}

			team2.length.times do |i|
			  team2_performances_update[i] = OneToN.new(away,away_new,all_nodes,vector_a,precision_array,pam_array,i)
			  team2_performances_new[i] = SumMessages.new(team2_performances[i], team2_performances_update[i],nil)
			end

			########### pErFOrManCEs tO sKILLs ############

			team1.length.times do |i|
			  team1_skills_update[i] = PerformanceToSkill.new(team1_skills[i],team1_performances[i],team1_performances_new[i],beta_squared)
			  if team1_old_update == nil
			  	team1_skills_new[i] = SumMessages.new(team1_skills[i], team1_skills_update[i], nil)
			  else
			  	team1_skills_new[i] = SumMessages.new(team1_skills[i], team1_skills_update[i], team1_old_update[i])
			  end
			end

			team2.length.times do |i|
			  team2_skills_update[i] = PerformanceToSkill.new(team2_skills[i],team2_performances[i],team2_performances_new[i],beta_squared)
			  if team2_old_update == nil
			  	team2_skills_new[i] = SumMessages.new(team2_skills[i], team2_skills_update[i], nil)
			  else
			  	team2_skills_new[i] = SumMessages.new(team2_skills[i], team2_skills_update[i], team2_old_update[i])
			  end
			end

			return [team1_skills_new, team2_skills_new, team1_skills_update, team2_skills_update]

		end
	end
end