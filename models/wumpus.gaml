/**
* Name: wumpus
* Author: eacg2@gcloud.ua.es
* Tags: Wumpus world
*/

model Wumpus_game

global {
	int num_wumpus<-3;
	int num_pits<-2;
	int num_players<-2;
	
	init {
		create goldArea number:1;
		create wumpusArea number: num_wumpus;
		create pitArea number: num_pits;
		create player number: num_players;
	}
	
	reflex stop when: length(goldArea) = 0 {
		do pause;
	}
	
	// variables globales estadisticas
	int total_simulation_steps <- 0;
	int dangers_avoided <- 0;
	int resultado_partida <- 0;
	
	// Reflex para incrementar el contador de steps en cada iteración
	reflex count_steps {
		total_simulation_steps <- total_simulation_steps + 1;
	}
	
	predicate patrol_desire <- new_predicate("patrol");
	predicate gold_desire <- new_predicate("gold");
	predicate go_back_desire <- new_predicate("goBack");
	
	string glitter_location <- "glitter_location";
	string odor_location <- "odor_location";
	string breeze_location <- "breeze_location";
	bool short <- false;
	
	int gridSize <- 20;      // Number of rows/columns in the grid
    float cellSize <- 100 / gridSize;
    
    list<float> moveValue <- [0.0, 90.0, 180.0, 270.0];
}


// ------------- WUMPUS -----------------
species odorArea{
	aspect base {
	  draw square(cellSize) color: #brown border: #black;		
	}
}

species wumpusArea{
	init {
		gworld place <- one_of(gworld);
		loop while: place.location={1,1}{
			place<-one_of(gworld);
		}
		location <- place.location;
		list<gworld> neighborns <- [];
		ask place {
			neighborns <- neighbors;
		}
		
		loop i over: neighborns {
			create odorArea{
				location <- i.location;
			}
		}
	}
	aspect base {
	  draw square(cellSize) color: #red border: #black;		
	}
}

// ------------- GOLD -----------------
species glitterArea{
	aspect base {
	  draw square(cellSize) color: rgb(0, 168, 22) border: #black;		
	}
}

species goldArea{
	init {
		gworld place <- one_of(gworld);
		location <- place.location;
		
		list<gworld> neighborns <- [];
		ask place {
			neighborns <- neighbors;
		}
		
		loop i over: neighborns {
			create glitterArea{
				location <- i.location;
			}
		}
	}
	
	
	perceive target:player in: 1{
		ask myself{
			do die;
		} 
	}
	
	aspect base {
	  draw square(cellSize) color: rgb(255, 230, 0) border: #black;		
	}
}

// ------------- PIT -----------------
species breezeArea{
	aspect base {
	  draw square(cellSize) color: #blue border: #black;		
	}
}


species pitArea{
	init {
		gworld place <- one_of(gworld);
		loop while: place.location={1,1}{
			place<-one_of(gworld);
		}
		location <- place.location;
		
		list<gworld> neighborns <- [];
		ask place {
			neighborns <- neighbors;
		}
		
		loop i over: neighborns {
			create breezeArea{
				location <- i.location;
			}
		}
	}
	
	aspect base {
	  draw square(cellSize) color: #black border: #black;		
	}
}

// ------------- PLAYER -----------------

species player skills: [moving] control: simple_bdi{
	
	rgb color <- #red;
	float mov;
	point lastPosition <- {-1,-1};
	bool wrongPlace <- false;
	init {
		gworld place <- gworld({1,1});
		location<-place.location;
		mov <- 0.0;
		do add_desire(patrol_desire);
	}
	
	perceive target:wumpusArea in: 1{ 
		ask myself{
			write "you have DIED";
			resultado_partida <- -1;
			do die;
			ask world{
				do pause;
			}
		} 
	}
	
	perceive target:pitArea in: 1{ 
		ask myself{
			write "you have DIED";
			resultado_partida <- -1;
			do die;
			ask world{
				do pause;
			}
		} 
	}
	
	perceive target:odorArea in: 1{ 
		focus id:"odor_location" var:location strength:10.0; 
		ask myself{
			wrongPlace <- true;
			if lastPosition = {-1, -1}{
				mov <- one_of(moveValue);
				do move heading: mov speed: cellSize;
			}
			
			// estadistica
			ask world {
				dangers_avoided <- dangers_avoided + 1;
			}
			
			do remove_desire(patrol_desire);
			do add_desire(go_back_desire);
		} 
	}
	
	perceive target:breezeArea in: 1{ 
		focus id:"breeze_location" var:location strength:10.0; 
		ask myself{
			wrongPlace <- true;
			if lastPosition = {-1, -1}{
				mov <- one_of(moveValue);
				do move heading: mov speed: cellSize;
			}
			// estadistica
			ask world {
				dangers_avoided <- dangers_avoided + 1;
			}
			
			do remove_desire(patrol_desire);
			do add_desire(go_back_desire);
		} 
	}
	
	plan patrolling intention: patrol_desire{
		mov <- one_of(moveValue);
		do move heading: mov speed: cellSize;
		lastPosition <- location;
	}
	
	plan goBack intention: go_back_desire{
		if mov = 0.0{
			mov <- 180.0;
		}else if mov = 90.0{
			mov <- 270.0;
		}else if mov = 180.0{
			mov <- 0.0;
		}else{
			mov <- 90.0;
		}
		wrongPlace <- false;
		do move heading: mov speed: cellSize;
		do remove_desire(go_back_desire);
		do add_desire(patrol_desire);
	}
	
	perceive target:glitterArea in: 1{ 
		write "glitter area (near gold)";
		focus id:"glitter_location" var:location strength:10.0; 
		ask myself{
			do remove_intention(patrol_desire, true);
		} 
	}
	
	perceive target:goldArea in: 1{ 
		write "GOLD TAKEN";
		resultado_partida <- 1;
		
		ask glitterArea{
			do die;
		} 
		
		ask goldArea{
			do die;
			ask world{
				do pause;
			}
		} 
	}
	
	// Reglas
	rule belief: new_predicate("glitter_location") new_desire: get_predicate(get_belief_with_name("glitter_location"));
	
	plan get_gold intention: new_predicate("glitter_location") priority:5{
		
		if short = true{
			if mov = 0.0{
				mov <- 180.0;
			}else if mov = 90.0{
				mov <- 270.0;
			}else if mov = 180.0{
				mov <- 0.0;
			}else{
				mov <- 90.0;
			}
			
			do move heading: mov speed: cellSize;
			short <- false;
		}else{
			mov <- one_of(moveValue);
			
			do move heading: mov speed: cellSize;
			short <- true;
		}
	}
	
	
	aspect bdi {
		draw circle(2) color: #magenta border: #black;
	}
}

grid gworld width: gridSize height: gridSize neighbors:4 {
	rgb color <- rgb(150, 250, 150) ;
}

// ------------- MAIN -----------------

experiment Wumpus_experimento_1 type: gui {
	   
	float minimum_cycle_duration <- 0.05;
	output {					
		display view1 { 
			grid gworld border: rgb(6, 115, 0);
			species goldArea aspect:base;
			species glitterArea aspect:base;
			species wumpusArea aspect:base;
			species odorArea aspect:base;
			species breezeArea aspect:base;
			species pitArea aspect:base;
			species player aspect:bdi;
		}
		
		display "Survival Statistics" {
        	chart "Danger avoided vs number of posible dangers" type: pie {
        		data "Dangers avoided " value: dangers_avoided ;
        		data "Number of posible dangers" value: num_wumpus + num_pits;
        	}
        }
        
        display "Steps Statistics" {
        	chart "Danger avoided in time (steps)" type: series {
        		data "Danger avoieded " value: dangers_avoided ;
        		
        	}
        }
        
        display "Elements Statistics" {
        	chart "Players, dangers, gold" type: pie {
        		data "Players " value: num_players;
        		data "Wumpus " value: num_wumpus;
        		data "Pits" value: num_pits;
        	}
        }
	}
}