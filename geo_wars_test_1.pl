#!/usr/bin/perl

#dependancy - imagemagick

use strict;
use warnings;
use SDL;
use SDL::Event;
use SDL::Events;
use SDLx::App;
use SDLx::Text;
use SDLx::Rect;
use SDLx::Sprite;


#Set-Up Window
my ($width, $height) = (640, 480);
my $app = SDLx::App->new( w => $width, h => $height, d => 32, title => 'Geometry Wars',
						  exit_on_quit => 1,
						  dt => 0.025);

#Creating a Triangle to use as player sprite. 
my $playersize = 20;
my $playersprite = SDLx::Sprite->new ( width => $playersize+1, height => $playersize+1 );
$playersprite->surface->draw_line([$playersize/2,0], [0,$playersize], [255, 255,0,255]);
$playersprite->surface->draw_line([$playersize/2,0], [$playersize,$playersize], [255, 255,0,255]);
$playersprite->surface->draw_line([0,$playersize], [$playersize/2,4*$playersize/5], [0, 255,0,255]);
$playersprite->surface->draw_line([$playersize,$playersize], [$playersize/2,4*$playersize/5], [0, 255,0,255]);

$playersprite->draw_xy($app, $app->w /2, $app->h /2);
#Resize mask.png to 40x40
`convert mask.png -resize 40x40 example.png`;

#Creating a list to hold all enemy object instances
my @enemy_instances = ();
my @enemy_sprites = ();
 
my $enemy_1 = SDLx::Sprite->new ( width => $playersize+1, height => $playersize+1 );
$enemy_1->load('example.png');
$enemy_sprites[0] = $enemy_1;

my $boundary = SDLx::Rect->new(25, 25, $app->w - 50, $app->h - 50);

#SDLx::Rect->new( 10, $app->h / 2, 20, 20 )
my $player = {
    ship => $playersprite,
    v_y    => 0,
    v_x	   => 0,
    score  => 0,
};

my @colors = (
    0xFFFFFFFF, #white
    0xFF0000FF, #red
    0x00FF00FF, #green
    0x0000FFFF, #blue
);

# initialize gun properties
my $gun_num = 0;
my @guns;
my $weapon_lvl = 2; # adjust this to upgrade gun

# initialize positions
reset_game();
create_enemy();
sub check_boundary {
	my ($A) = @_;
	#Checking for boundary 
	$A->{ship}->x < 14 && $A->{v_x} < 0 && ($A->{v_x} = 0);
    $A->{ship}->y < 14 && $A->{v_y} < 0 && ($A->{v_y} = 0);
    $A->{ship}->x > $app->w - 35 && $A->{v_x} > 0 && ($A->{v_x} = 0);
    $A->{ship}->y > $app->h - 35 && $A->{v_y} > 0 && ($A->{v_y} = 0);
}

sub reset_game {
	$app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x22114200 );
		
		$app->draw_rect( [ 10, 10, $app->w-20, $app->h-20 ], 0x000000 );
}

$app->add_event_handler(
	sub {
		my ( $event, $app ) = @_;
        if ( $event->type == SDL_KEYDOWN ) {
            if ( $event->key_sym == SDLK_UP ) {
                $player->{v_y} = -7;
            }
            elsif ( $event->key_sym == SDLK_DOWN ) {
                $player->{v_y} = 7;
            }
            if ( $event->key_sym == SDLK_LEFT ) {
                $player->{v_x} = -7;
            }
            elsif ( $event->key_sym == SDLK_RIGHT ) {
                $player->{v_x} = 7;
            }
            if ($event->key_sym == SDLK_SPACE ){
                # gun velocity and size increases with weapon level
                $gun_num += 1;
                my $gun_ = {
                    p_y => $player->{ship}->y,
                    p_x => $player->{ship}->x,
                    color => $colors[$weapon_lvl],
                    velocity => 10 * ($weapon_lvl+1),
                    diameter => 3 * ($weapon_lvl+1),
                };
                push(@guns, $gun_);
            }
            
        }
        elsif ( $event->type == SDL_KEYUP ) {
            if (   $event->key_sym == SDLK_UP
                or $event->key_sym == SDLK_DOWN )
            {
                $player->{v_y} = 0;
            }
            
            if (   $event->key_sym == SDLK_LEFT
                or $event->key_sym == SDLK_RIGHT )
            {
                $player->{v_x} = 0;
            }
        }
    }
);

# handles the player's movement
$app->add_move_handler( sub {
    my ( $step, $app ) = @_;
    my $ship = $player->{ship};
	
	check_boundary($player);
    
    $ship->y( int($ship->y + ( $player->{v_y} * $step )) );
    $ship->x( int($ship->x + ( $player->{v_x} * $step )) );
    
#calc_laser
    # Calculate how gun shots move
    my $gun;
    my $counter = 0;
    foreach $gun (@guns){
        $gun->{p_y} -= $gun->{velocity} * $step;
        $gun->{p_x} += 1.3 * $player->{v_x} * $step;
        if ($gun->{p_y} > $app->h - 35) {splice(@guns,$counter,1)};
        $counter++;
    }
});

#Create Enemy
sub create_enemy 
{
	my $enem = {
    sprite => $enemy_sprites[int(rand(scalar(@enemy_sprites))) ],
    v_y    => rand(2)-1, #Change to something more appropriate
    v_x	   => rand(2)-1,
	};
	$enem->{sprite}->draw_xy($app, $app->w /2, $app->h /2);
	push @enemy_instances, $enem; 
}

#Load all enemies
sub load_enemies
{
	#First update positions of enemies
	#Then Draw on canvas
	
	foreach my $inst (@enemy_instances) {
		$app->add_move_handler( sub {
			my ( $step, $app ) = @_;
			$inst->{sprite}->y( int($inst->{sprite}->y + ( $inst->{v_y} * $step )) );
			$inst->{sprite}->x( int($inst->{sprite}->x + ( $inst->{v_x} * $step )) );
		});
		$inst->{sprite}->draw($app);
	}
	
}

$app->add_show_handler(
    sub {
        # first, we clear the screen
        $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x22114200 );
		
		$app->draw_rect( [ 10, 10, $app->w-20, $app->h-20 ], 0x000000 );
		
        # then we render each ship
        #$app->draw_rect( $player->{ship}, 0xFF0000FF );
		$playersprite->draw($app);
		load_enemies();
        # then we render the guns
        my $gun;
        foreach $gun (@guns){
            $app->draw_rect( [ $gun->{p_x}, $gun->{p_y}, $gun->{diameter}, $gun->{diameter}*2 ], $gun->{color} );
        }

        # finally, we update the screen
        $app->update;
    }
);

# all is set, run the app!
$app->run();
