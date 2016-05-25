require File.dirname(__FILE__)+'/gaussian.rb'

class Player
  attr_reader :player_id 
  attr_accessor :mean, :var, :field_time
  def initialize(player_id)
    @player_id = player_id
    @mean = 25.0
    @var = (25.0/3.0)**2
    @field_time = 1
  end
end

class Player_alt
  attr_reader :player_id 
  attr_accessor :mean, :var, :field_time
  def initialize(hash)
    @player_id = hash["ID"].to_f
    @mean = hash["Mean"].to_f
    @var = (hash["Variance"].to_f)**2
    @field_time = 1
  end
end

class PriorToSkill
  attr_accessor :precision, :pam
  attr_reader :field_time
  def initialize(player, tau)
    @precision = 1/(player.var+tau)
    @pam = player.mean*precision
    @field_time = player.field_time
  end
end

class SkillToPerformance
  attr_accessor :precision, :pam
  attr_reader :field_time
  def initialize(skill, beta_square, old_skill)
    if old_skill == nil
		small_a = 1/(1+beta_square*skill.precision)
		@precision = small_a*skill.precision
		@pam = small_a*skill.pam 
		@field_time = skill.field_time
	else
		small_a = 1/(1+beta_square*(skill.precision-old_skill.precision))
		@precision = small_a*(skill.precision-old_skill.precision)
		@pam = small_a*(skill.pam-old_skill.pam)
		@field_time = skill.field_time
	end
  end
end

class NToOne
  attr_accessor :precision, :pam, :field_time
  def initialize (vector_a, all_nodes)
    precision_array = vector_a.zip(all_nodes).map {|a, nodes| (a**2)*(nodes.field_time**2)/nodes.precision}
    precision_total = precision_array.inject(0){|sum, item| sum + item}
    @precision = 1/precision_total
    pam_array = vector_a.zip(all_nodes).map {|a, nodes| a*(nodes.field_time*nodes.pam)/nodes.precision}
    pam_total = pam_array.inject(0){|sum, item| sum + item}
    @pam = precision*pam_total
    @field_time = 1
  end
end

class OneToNTeams
  attr_accessor :precision, :pam, :field_time
  def initialize (original, update, all_nodes, vector_a, precision_array, pam_array, i)
    @precision = (1/((vector_a[i]**2)*(all_nodes[i].field_time**2)*(1/(original.precision-update.precision)+(1/original.precision-precision_array[i]))))
    pam1 = precision/(vector_a[i]*all_nodes[i].field_time)
    pam2 = ((original.pam-update.pam)/(original.precision-update.precision)-(original.pam/original.precision)-(pam_array[i]))
    @pam = -pam1*pam2
    @field_time = 1
  end  
end

class OneToNDiff
  attr_accessor :precision, :pam, :field_time
  def initialize (original, update, all_nodes, vector_a, precision_array, pam_array, i)
    @precision = (1/((vector_a[i]**2)*(all_nodes[i].field_time**2)*(1/(update.precision-original.precision)+(1/original.precision-precision_array[i]))))
    pam1 = precision/(vector_a[i]*all_nodes[i].field_time)
    pam2 = ((update.pam-original.pam)/(update.precision-original.precision)-(original.pam/original.precision)+(pam_array[i]))
    @pam = pam1*pam2
    @field_time = 1
  end  
end

class OneToN
  attr_accessor :precision, :pam, :field_time
  def initialize (original, update, all_nodes, vector_a, precision_array, pam_array, i)
    @precision = 1/((1/((vector_a[i]**2)*(all_nodes[i].field_time**2)))*(1/(update.precision-original.precision)+(1/original.precision-precision_array[i])))
    pam1 = precision/(vector_a[i]*all_nodes[i].field_time)
    pam2 = ((update.pam-original.pam)/(update.precision-original.precision)-(original.pam/original.precision)+(pam_array[i]))
    @pam = pam1*pam2
    @field_time = 1
  end  
end

class PerformanceToSkill
  attr_accessor :precision, :pam
  attr_reader :field_time
  def initialize(skill, original, update, beta_square)
    small_a = 1/(1+beta_square*(update.precision-original.precision))
    @precision = small_a*(update.precision-original.precision)
    @pam = small_a*(update.pam-original.pam)
    @field_time = skill.field_time
  end
end

class ResultWin
  attr_accessor :precision, :pam, :field_time
  
  @@sqrt2 = Math.sqrt(2).freeze
  @@inv_sqrt_2pi = (1 / Math.sqrt(2 * Math::PI)).freeze
  
  def cdf(x)
    0.5 * (1 + Math.erf(x / @@sqrt2))
  end
  
  def pdf(x)
    @@inv_sqrt_2pi * Math.exp(-0.5 * (x**2))
  end
  
  def initialize(team_difference,eta)
    t = team_difference.pam/Math.sqrt(team_difference.precision)
    top_line = pdf(t-eta*Math.sqrt(team_difference.precision))
    bottom_line = cdf(t-eta*Math.sqrt(team_difference.precision))
    w_tau_eta = (top_line/bottom_line)*((top_line/bottom_line) + t - eta*Math.sqrt(team_difference.precision))
    @precision = team_difference.precision/(1-w_tau_eta)
    @pam = (team_difference.pam + Math.sqrt(team_difference.precision)*top_line/bottom_line)/(1-w_tau_eta)
  end
end

class ResultDraw
  attr_accessor :precision, :pam, :field_time
  
  @@sqrt2 = Math.sqrt(2).freeze
  @@inv_sqrt_2pi = (1 / Math.sqrt(2 * Math::PI)).freeze
  
  def cdf(x)
    0.5 * (1 + Math.erf(x / @@sqrt2))
  end
  
  def pdf(x)
    @@inv_sqrt_2pi * Math.exp(-0.5 * (x**2))
  end
  
  def initialize(team_difference,eta)
    t = team_difference.pam/Math.sqrt(team_difference.precision)
    top_line = pdf(0-eta*Math.sqrt(team_difference.precision)-t)-pdf(eta*Math.sqrt(team_difference.precision)-t)
    bottom_line = 0 - cdf(0-eta*Math.sqrt(team_difference.precision)-t)+cdf(eta*Math.sqrt(team_difference.precision)-t)
    
    w_tau_top = (eta*Math.sqrt(team_difference.precision)-t)*pdf(eta*Math.sqrt(team_difference.precision)-t)+(eta*Math.sqrt(team_difference.precision)+t)*pdf(eta*Math.sqrt(team_difference.precision)+t)
    w_tau_eta = ((top_line/bottom_line)**2) + w_tau_top/bottom_line
    
    @precision = team_difference.precision/(1-w_tau_eta)
    @pam = (team_difference.pam + Math.sqrt(team_difference.precision)*top_line/bottom_line)/(1-w_tau_eta)
  end
end

class SumMessages
  attr_accessor :precision, :pam, :field_time
  def initialize(original, update, old_update)
    if old_update == nil
    	@precision = original.precision + update.precision
    	@pam = original.pam + update.pam
    else
      	@precision = original.precision + update.precision - old_update.precision
    	@pam = original.pam + update.pam - old_update.pam
    end
  end
end
