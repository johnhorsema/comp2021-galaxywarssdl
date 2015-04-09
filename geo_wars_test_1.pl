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
						  exit_on_quit => 1);

#Creating a Triangle to use as player sprite. 
my $playersize = 20;
my $playersprite = SDLx::Sprite->new ( width => $playersize+1, height => $playersize+1 );
$playersprite->surface->draw_line([$playersize/2,0], [0,$playersize], [255, 255,0,255]);
$playersprite->surface->draw_line([$playersize/2,0], [$playersize,$playersize], [255, 255,0,255]);
$playersprite->surface->draw_line([0,$playersize], [$playersize/2,4*$playersize/5], [0, 255,0,255]);
$playersprite->surface->draw_line([$playersize,$playersize], [$playersize/2,4*$playersize/5], [0, 255,0,255]);

#SDLx::Rect->new( 10, $app->h / 2, 20, 20 )
my $player = {
    ship => $playersprite,
    v_y    => 0,
    v_x	   => 0,
    score  => 0,
};

# initialize positions
reset_game();

sub check_collision {
    my ($A, $B) = @_;

    return if $A->bottom < $B->top;
    return if $A->top    > $B->bottom;
    return if $A->right  < $B->left;
    return if $A->left   > $B->right;

    # if we got here, we have a collision!
    return 1;
}

sub reset_game {
}

$app->add_event_handler(
	sub {
		my ( $event, $app ) = @_;
        if ( $event->type == SDL_KEYDOWN ) {
            if ( $event->key_sym == SDLK_UP ) {
                $player->{v_y} = -7;
            }
            elsif ( $event->key_sym == SDLK_DOWN ) {
                $player->{v_y} = 12;
            }
            if ( $event->key_sym == SDLK_LEFT ) {
                $player->{v_x} = -7;
            }
            elsif ( $event->key_sym == SDLK_RIGHT ) {
                $player->{v_x} = 12;
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

    $ship->y( int($ship->y + ( $player->{v_y} * $step )) );
    $ship->x( int($ship->x + ( $player->{v_x} * $step )) );
    
});

$app->add_show_handler(
    sub {
        # first, we clear the screen
        $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000 );


        # then we render each ship
        #$app->draw_rect( $player->{ship}, 0xFF0000FF );
		$playersprite->draw($app);
      

        # finally, we update the screen
        $app->update;
    }
);

# all is set, run the app!
$app->run();
