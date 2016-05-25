require File.dirname(__FILE__)+'/trueskill_classes.rb'
require File.dirname(__FILE__)+'/gaussian.rb'
require File.dirname(__FILE__)+'/update.rb'
require File.dirname(__FILE__)+'/estimate.rb'

require 'csv'

def csv(file)
  File.open(file) do|f|
    columns = f.readline.chomp.split(',')

    table = []
    until f.eof?
      row = f.readline.chomp.split(',')
      row = columns.zip(row).flatten
      table << Hash[*row]
    end

    return columns, table
  end
end

############### OPEN CSV FILES CONTAINING PLAYER DB, HOME TEAM DATA, AWAY TEAM DATA

columns, player_db = csv('player_db.csv')

columns1, home = csv('match_home.csv')
columns2, away = csv('match_away.csv')
columns3, results = csv('match_example.csv')

############### GO THROUGH EACH MATCH AND UPDATE PLAYER SKILLS

team1_update = Array.new(results.length)
team2_update = Array.new(results.length)
team1_update_temp = Array.new(results.length)
team2_update_temp = Array.new(results.length)

for iter in 0..1000

for temp in 0..65 #results.length-1

if iter % 2 == 1
	match = results.length - 1 - temp
else
	match = temp
end

team1 = Array.new(home[match].length/2)
team2 = Array.new(away[match].length/2)

home_length = -1
away_length = -1

draw_probability = 0.1
beta_squared = ((25.0/3.0)/2.0)**2.0
tau = ((25.0/3.0)/100.0)**2.0

if iter > 0
	tau = 0
end

############### FILL TEAM DATA

for i in 0..((home[match].length/2)-1)
 if home[match]["Player"+"#{i+1}"] != nil
   id = home[match]["Player"+"#{i+1}"]
   temp = player_db.find {|row| row['ID'] == "#{id}"}
   if temp.nil? == true
     player_db[player_db.length] = {"ID"=>"#{id}","Mean"=>"25","Variance"=>"8.333"}
   end
   temp = player_db.find {|row| row['ID'] == "#{id}"}
   team1[i] = Player_alt.new(temp)
   home_length = home_length+1
 end
end

for i in 0..((away[match].length/2)-1)
 if away[match]["Player"+"#{i+1}"] != nil
   id = away[match]["Player"+"#{i+1}"]
   temp = player_db.find {|row| row['ID'] == "#{id}"}
   if temp.nil? == true
     player_db[player_db.length] = {"ID"=>"#{id}","Mean"=>"25","Variance"=>"8.333"}
   end
   temp = player_db.find {|row| row['ID'] == "#{id}"}
   team2[i] = Player_alt.new(temp)
   away_length = away_length+1
 end
end

if results[match]["Home"] == nil
	results[match]["Home"] = "0"
end

if results[match]["Away"] == nil
	results[match]["Away"] = "0"
end	

if results[match]["Home"] > results[match]["Away"]
    results_update = 1
    elsif results[match]["Home"] < results[match]["Away"]
    results_update = -1
    else results_update = 0
end

if iter == 0
	team1_new, team2_new, team1_update[match], team2_update[match] = Skills.update(team1[0..home_length], team2[0..away_length], draw_probability, beta_squared, tau, results_update, nil, nil)
else
	team1_new, team2_new, team1_update[match], team2_update[match] = Skills.update(team1[0..home_length], team2[0..away_length], draw_probability, beta_squared, tau, results_update, team1_update[match], team2_update[match])
end

testresult = Prediction.update(team1[0..home_length], team2[0..away_length], draw_probability, beta_squared, tau)

for i in 0..home_length 
  if home[match]["Player"+"#{i+1}"] != nil
    id = home[match]["Player"+"#{i+1}"]
    id = player_db.rindex {|row| row['ID'] == "#{id}"}
    mean = team1_new[i].pam/team1_new[i].precision
    variance = Math.sqrt(1/team1_new[i].precision)
    player_db[id]["Mean"] = mean.to_s
    player_db[id]["Variance"] = variance.to_s
  end
end 

for i in 0..away_length
  if away[match]["Player"+"#{i+1}"] != nil
    id = away[match]["Player"+"#{i+1}"]
    id = player_db.rindex {|row| row['ID'] == "#{id}"}
    mean = team2_new[i].pam/team2_new[i].precision
    variance = Math.sqrt(1/team2_new[i].precision)
    player_db[id]["Mean"] = mean.to_s
    player_db[id]["Variance"] = variance.to_s
  end
end 

team1.clear
team2.clear
team1_new.clear
team2_new.clear
 
end

puts player_db[1]["Mean"]

end

CSV.open("player_test.csv", "w") do |csv|
    csv << ["ID", "Mean", "Variance"]
    for i in 0..player_db.length-1
        csv << [player_db[i]["ID"], player_db[i]["Mean"], player_db[i]["Variance"]]
    end
end