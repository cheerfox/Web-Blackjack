require 'rubygems'
require 'sinatra'
require 'pry'
# set :sessions, true
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'cheerfox'

BLACKJACK_AMOUNT = 21
DEALER_HIT_MINIMUN = 17

#use instance variable to handle success message and don't display hit or stay button when  busted
#before filter
#starover nav
#image for cards 
#css fix for hit stay btn and cards images
#handle busted and blackjack condition
#pevent empty player_name

#play again
#helper method winner loser tie
#more precise message
#Use constant for magic number
#Hide the first card for dealer and flip it after player stay
#bet mechnism

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
      point -= 10 if point > BLACKJACK_AMOUNT
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

  def winner!(message)
    @show_hit_or_stay_button = false
    @success = "Congradulations #{session[:player_name]} win!! #{message}"
    @play_again = true
  end

  def loser!(message)
    @show_hit_or_stay_button = false
    @error = "Sorry! #{session[:player_name]} Lose!! #{message}"
    @play_again = true
  end

  def tie!(message)
    @show_hit_or_stay_button = false
    @success = "It's tie!! #{message}"
    @play_again = true
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
  if player_point > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} is busted at #{player_point}!!!")
  elsif player_point == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit Blackjack!!")
  end
  erb :game
end

post '/game/player/stay' do
  @success = "You stay in #{total_point(session[:player_cards])}"
  @show_hit_or_stay_button = false
  redirect 'game/dealer'
end

get '/game/dealer' do
  dealer_point = total_point(session[:dealer_cards])
  if dealer_point > BLACKJACK_AMOUNT
    winner!(" Dealer is busted at #{dealer_point}!!")
  elsif dealer_point == BLACKJACK_AMOUNT
    loser!("Dealer is Blackjack")
  elsif dealer_point > DEALER_HIT_MINIMUN
    redirect '/game/compare'
  else
    @show_hit_or_stay_button = false
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
    winner!("Your point are #{player_point}, Dealer's point is #{dealer_point}")
  elsif player_point < dealer_point
    loser!("Your point are #{player_point}, Dealer's point is #{dealer_point}")
  else
    tie!("Tie at #{player_point}")
  end
  erb :game

end

get '/game_over' do
  erb :game_over
end

