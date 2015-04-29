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
my ($width, $height) = (800, 600);
my $app = SDLx::App->new( w => $width, h => $height, d => 32, title => 'Galaxy Wars SDL',
						  exit_on_quit => 1,
						  dt => 0.025);

#Create cover
my $cover = SDLx::Surface->load('cover.png');
#Cover text
my $covertxt = SDLx::Text->new(x => ($width-340)/2, y => $height/2, font => 'font.ttf', h_align => 'right', text => '- Press any key to start -' );

#Create background
my $bg = SDLx::Sprite->new(width => $width-20, height => $height-20);
$bg->load('bg.png');

my $start_game = 0;

#Creating a Triangle to use as player sprite. 
my $playersize = 35;
my $playersprite = SDLx::Sprite->new ( width => $playersize, height => $playersize*1.6 );
#Resise ship to 40x40
`convert ship.png -resize 35x56 ship_01.png`;
$playersprite->load('ship_01.png');

#$playersprite->surface->draw_line([$playersize/2,0], [0,$playersize], [255, 255,0,255]);
#$playersprite->surface->draw_line([$playersize/2,0], [$playersize,$playersize], [255, 255,0,255]);
#$playersprite->surface->draw_line([0,$playersize], [$playersize/2,4*$playersize/5], [0, 255,0,255]);
#$playersprite->surface->draw_line([$playersize,$playersize], [$playersize/2,4*$playersize/5], [0, 255,0,255]);

#Player spawn at center
$playersprite->draw_xy($app, $app->w /2, $app->h /2);

#Resize alien.png to 40x60
`convert alien.png -resize 40x60 alien_01.png`;

#Creating a list to hold all enemy object instances
my @enemy_instances = ();
my @enemy_sprites = ();
 
my $enemy_1 = SDLx::Sprite->new ( width => $playersize+1, height => $playersize+1, image=>'alien_01.png');
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
my $weapon_lvl = 0; # adjust this to upgrade gun

# initialize positions
reset_game();
create_enemy();

sub start_screen {
    $cover->blit( $app );
    $covertxt->write_to( $app );
}

sub check_boundary {
	my ($A) = @_;
	#Checking for boundary 
	$A->{ship}->x < 5 && $A->{v_x} < 0 && ($A->{v_x} = 0);
    $A->{ship}->y < 10 && $A->{v_y} < 0 && ($A->{v_y} = 0);
    $A->{ship}->x > $app->w - 40 && $A->{v_x} > 0 && ($A->{v_x} = 0);
    $A->{ship}->y > $app->h - 60 && $A->{v_y} > 0 && ($A->{v_y} = 0);
}

sub check_enemy_shot {
	foreach my $inst (@enemy_instances) {
		foreach my $shot (@guns) {
			if (((-20 + $shot->{p_x}-$inst->{sprite}->x)**2 + ($shot->{p_y}-$inst->{sprite}->y)**2) < 350  )
			{
				my @temp_enems = ();
				foreach my $i (0..(-1 + scalar @enemy_instances))
				{
					if( \$inst != \$enemy_instances[$i])
					{
						push @temp_enems, $enemy_instances[$i];
					}
				}
				@enemy_instances = @temp_enems;
			} 
				
		}
	}
}

sub delete_gun {
	my @temp_guns = ();
	foreach my $i (0..(-1 + scalar @guns))
	{
		if ($guns[$i]->{p_y} > 20)
		{
			push @temp_guns, $guns[$i];
		}
	}
    warn "gunnumb4:",scalar @guns,"\n";
	@guns = @temp_guns;
    warn "gunnumaftr:",scalar @guns,"\n";
}


sub reset_game {
    $app->draw_rect( [ 0, 0, $app->w-20, $app->h-20 ], 0x000000 );
    #Render bg img
    $bg->draw_xy( $app, 0, 0 );
}

$app->add_event_handler(
	sub {
		my ( $event, $app ) = @_;
        if ( $event->type == SDL_KEYDOWN ) {
            if(!$start_game){
                $start_game = 1;
            }
            if($event->key_sym == SDLK_p)
            {
				create_enemy();
				load_enemies();
				#$app->update;
			}
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
                # create gun instance and push
                my $gun_ = {
                    p_y => $player->{ship}->y,
                    p_x => $player->{ship}->x+15,
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
        # Swerve the shot horizontally
        $gun->{p_x} += 0.4 * $player->{v_x} * $step;
        if ($gun->{p_y} > $app->h - 35) {splice(@guns,$counter,1)};
        $counter++;
    }
});

#Create Enemy
sub create_enemy 
{
	my $enem = {
    sprite => SDLx::Sprite->new ( width => $playersize+1, height => $playersize+1, image=>'alien_01.png'),
    v_y    => 1, #Change to something more appropriate
    v_x	   => 0,
	};
	$enem->{sprite}->draw_xy($app, rand($app->w), 10 + rand($app->h/2) );
	push @enemy_instances, $enem; 
	warn "num of enemies:",scalar @enemy_instances;
}

#Load all enemies
sub load_enemies
{
	#First update positions of enemies
	#Then Draw on canvas
	
	foreach my $inst (@enemy_instances) {
		
		$app->add_move_handler( sub {
			my ( $step, $app ) = @_;
			if(int rand 300 == 1)
			{$inst->{sprite}->y( int($inst->{sprite}->y + ( $inst->{v_y} )) );}
			$inst->{sprite}->x( int($inst->{sprite}->x + ( $inst->{v_x} * $step )) );
		});
		
		$inst->{sprite}->draw($app);
		
		
		
	}
	
}

$app->add_show_handler(
    sub {
        # show start screen
        if(!$start_game){
            start_screen();
        }
        else{
            # first, we clear the screen
            reset_game();
            # then we render player ship
            $playersprite->draw($app);
            
            if(int rand 500 == 1 || scalar @enemy_instances == 1)
            {create_enemy();}
            # then we render enemies
            load_enemies();
            
            # then we render the guns
            my $gun;
            foreach $gun (@guns){
                $app->draw_rect( [ $gun->{p_x}, $gun->{p_y}, $gun->{diameter}, $gun->{diameter}*2 ], $gun->{color} );
            }
            check_enemy_shot();
            delete_gun();
        }

        # finally, we update the screen
        $app->update;
    }
);

# all is set, run the app!
$app->run();
