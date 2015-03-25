require 'rubygems'
require 'sinatra'
require 'pry'
# set :sessions, true
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'cheerfox'


#use instance variable to handle success message and don't display hit or stay button when  busted
#before filter
#starover nav
#image for cards 
#css fix for hit stay btn and cards images
#handle busted and blackjack condition
#pevent empty player_name

helpers do

  def total_point(cards)
    point = 0
    cards.each do |card|
      if card[1] == 'J' || card[1] == 'Q' || card[1] == 'K'
        point += 10
      elsif card[1] == 'A'
        point += 11
      else
        point += card[1].to_i
      end
    end
  #correct ace
    cards.select {|card| card[1] == 'A'}.count.times do
      point -= 10 if point > 21
    end
    point
  end

  def card_image(card)
    suit = case card[0]
      when 'C' then 'clubs'
      when 'D' then 'Diamonds'
      when 'H' then 'Hearts'
      when 'S' then 'Spades'
    end
    number = card[1]
    number = case number
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      when 'A' then 'ace'
      else number
    end
    "<img class='card_image' src='/images/cards/#{suit}_#{number}.jpg'>"
  end

end 

before do
  @show_hit_or_stay_button = true
end

get '/' do 
  if session[:play_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "You must enter a Player name"
    halt erb :new_player
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  #set initial value
  suits = ['H', 'D', 'S', 'C']
  numbers = ['2', '3', '4', '5', '6', '7', '8', '9', '10' ,'J', 'Q', 'K']
  session[:deck] = suits.product(numbers).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  #deal cards
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  #render the template
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_point = total_point(session[:player_cards])
  if player_point > 21
    @error = "Sorry, #{session[:player_name]} Busted!!!"
    @show_hit_or_stay_button = false
  elsif player_point == 21
    @success = "Congradulations!! #{session[:player_name]} hit Blackjack!!"
    @show_hit_or_stay_button = false
  end
  erb :game
end

post '/game/player/stay' do
  @success = "You stay in #{total_point(session[:player_cards])}"
  @show_hit_or_stay_button = false
  redirect 'game/dealer'
end

get '/game/dealer' do
  @show_hit_or_stay_button = false
  dealer_point = total_point(session[:dealer_cards])
  if dealer_point > 21
    @success = "Congradulations!! Dealer is busted!! You win!!"
  elsif dealer_point == 21
    @error = "Sorry, dealer is Blackjack, You Lose!!!"
  elsif dealer_point >17
    redirect '/game/compare'
  else
    @show_dealer_next_card = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_button = false
  player_point = total_point(session[:player_cards])
  dealer_point = total_point(session[:dealer_cards])
  if player_point > dealer_point
    @success = "You Win!!!"
  elsif player_point < dealer_point
    @error = "You Lose!!!"
  else
    @success = "It's tie!!"
  end
  erb :game

end

