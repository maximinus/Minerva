#include <gtk/gtk.h>

static void print_hello (GtkWidget *widget, gpointer data)
{
    g_print ("Hello World\n");
}


static void quit_activated(GSimpleAction *action, GVariant *parameter, GApplication *application) {
    g_application_quit(application);
}

static void activate (GApplication *application) {
    GtkWidget *box;
    GtkWidget *text;
    GtkWidget *button;

    GtkApplication *app = GTK_APPLICATION(application);
    GtkWidget *window = gtk_application_window_new(GTK_APPLICATION (app));
    gtk_window_set_title(GTK_WINDOW(window), "Minerva Lisp IDE");
    gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
    gtk_application_window_set_show_menubar(GTK_APPLICATION_WINDOW(window), TRUE);

    // pack a container in the window
    box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_set_halign(box, GTK_ALIGN_FILL);
    gtk_widget_set_valign(box, GTK_ALIGN_FILL);
    gtk_widget_set_margin_top(box, 16);
    gtk_widget_set_margin_bottom(box, 16);
    gtk_widget_set_margin_start(box, 16);
    gtk_widget_set_margin_end(box, 16);
    gtk_window_set_child(GTK_WINDOW(window), box);

    // and a text widget
    text = gtk_text_view_new();
    gtk_widget_set_halign(text, GTK_ALIGN_FILL);
    gtk_widget_set_valign(text, GTK_ALIGN_FILL);
    gtk_widget_set_vexpand(text, TRUE);
    gtk_widget_set_hexpand(text, TRUE);

    // and a button at the bottom
    button = gtk_button_new_with_label ("Click Me");
    g_signal_connect(button, "clicked", G_CALLBACK(print_hello), NULL);

    gtk_box_append(GTK_BOX(box), text);
    gtk_box_append(GTK_BOX(box), button);

    gtk_widget_show(window);
}


static void startup(GApplication* application)
{
    GtkApplication *app = GTK_APPLICATION(application);

    // this is too complex for a simple menu
    GSimpleAction *act_quit = g_simple_action_new("quit", NULL);
    g_action_map_add_action(G_ACTION_MAP(app), G_ACTION(act_quit));
    g_signal_connect(act_quit, "activate", G_CALLBACK(quit_activated), app);

    GMenu *menubar = g_menu_new();
    GMenuItem *menu_item_menu = g_menu_item_new("Menu", NULL);
    GMenu *menu = g_menu_new();
    GMenuItem *menu_item_quit = g_menu_item_new("Quit", "app.quit");

    g_menu_append_item(menu, menu_item_quit);
    g_object_unref(menu_item_quit);
    g_menu_item_set_submenu(menu_item_menu, G_MENU_MODEL(menu));
    g_menu_append_item(menubar, menu_item_menu);
    g_object_unref(menu_item_menu);
    gtk_application_set_menubar(GTK_APPLICATION(app), G_MENU_MODEL(menubar));
}

int main (int argc, char **argv)
{
    GtkApplication *app;
    int status;

    app = gtk_application_new("org.gtk.Minerva", G_APPLICATION_FLAGS_NONE);
    g_signal_connect (app, "startup", G_CALLBACK (startup), NULL);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);

    return status;
}
