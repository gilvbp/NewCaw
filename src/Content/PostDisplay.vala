/* PostDisplay.vala
 *
 * Copyright 2021 Frederick Schenk
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using GLib;

/**
 * Displays the content of one Post.
 */
[GtkTemplate (ui="/uk/co/ibboard/Cawbird/ui/Content/PostDisplay.ui")]
public class PostDisplay : Gtk.Box {

  /**
   * How the content will be displayed.
   */
  public enum DisplayType {
    /**
     * Will be normally displayed, designed for use in a list.
     */
    LIST,
    /**
     * Added interactive elements, designed for selected posts.
     */
    MAIN,
    /**
     * Smaller display, used for quoted posts.
     */
    QUOTE
  }

  // UI-Elements for the repost display
  [GtkChild]
  private unowned Gtk.Box repost_status_box;
  [GtkChild]
  private unowned UserAvatar repost_avatar;
  [GtkChild]
  private unowned Gtk.Label repost_display_label;
  [GtkChild]
  private unowned BadgesBox repost_badges;
  [GtkChild]
  private unowned Gtk.Label repost_name_label;
  [GtkChild]
  private unowned Gtk.Label repost_time_label;

  // UI-Elements for the post information
  [GtkChild]
  private unowned UserAvatar author_avatar;
  [GtkChild]
  private unowned Gtk.Label author_display_label;
  [GtkChild]
  private unowned BadgesBox author_badges;
  [GtkChild]
  private unowned Gtk.Label author_name_label;
  [GtkChild]
  private unowned Gtk.Label post_info_label;
  [GtkChild]
  private unowned Gtk.Label post_time_label;

  // UI-Elements for the text
  [GtkChild]
  private unowned Gtk.Label post_text_label;

  // UI-Elements for the additional content
  [GtkChild]
  private unowned MediaPreview media_previewer;
  [GtkChild]
  private unowned Gtk.ListBox quote_container;

  // UI-Elements for the post metrics
  [GtkChild]
  private unowned Gtk.Box post_metrics_box;
  [GtkChild]
  private unowned Gtk.Label post_likes_display_label;
  [GtkChild]
  private unowned Gtk.Label post_reposts_display_label;
  [GtkChild]
  private unowned Gtk.Box post_replies_display_box;
  [GtkChild]
  private unowned Gtk.Label post_replies_display_label;

  // UI-Elements for the action box
  [GtkChild]
  private unowned Gtk.Box post_actions_box;
  [GtkChild]
  private unowned Adw.ButtonContent post_like_button_display;
  [GtkChild]
  private unowned Adw.ButtonContent post_repost_button_display;
  [GtkChild]
  private unowned Adw.ButtonContent post_reply_button_display;
  [GtkChild]
  private unowned Gtk.MenuButton post_options_button;

  /**
   * Creates a new PostDisplay widget displaying a specific Post.
   *
   * @param post The Post which is to be displayed in this widget.
   */
  public PostDisplay (Backend.Post post, DisplayType display_type = LIST) {
    // Store the post to display
    displayed_post = post;

    // Determine which post to show in main view
    bool show_repost = false;
    if (post.post_type == REPOST) {
      show_repost = true;
      main_post   = post.referenced_post;
    } else {
      main_post = displayed_post;
    }

    // Set up the repost display
    if (show_repost) {
      // Display the repost status box
      repost_status_box.visible  = true;

      // Set up information about the reposting user
      repost_avatar.set_avatar (displayed_post.author.avatar);
      repost_display_label.label = displayed_post.author.display_name;
      repost_name_label.label    = "@" + displayed_post.author.username;
      repost_time_label.label    = DisplayUtils.display_time_delta (displayed_post.creation_date);

      // Set up badges for the author
      repost_badges.display_verified  = displayed_post.author.has_flag (VERIFIED);
      repost_badges.display_bot       = displayed_post.author.has_flag (BOT);
      repost_badges.display_protected = displayed_post.author.has_flag (PROTECTED);
    }

    // Hint for the user where the post can be opened in the browser
    string open_link_label = _("Open on %s").printf (main_post.domain);

    // Set up the author avatar
    author_avatar.set_avatar (main_post.author.avatar);

    // Set up badges for the author
    author_badges.display_verified  = main_post.author.has_flag (VERIFIED);
    author_badges.display_bot       = main_post.author.has_flag (BOT);
    author_badges.display_protected = main_post.author.has_flag (PROTECTED);

    // Set up the post information area
    author_display_label.label = main_post.author.display_name;
    author_name_label.label    = "@" + main_post.author.username;
    if (display_type == MAIN) {
      // Add date and source to info label
      string date_text        = main_post.creation_date.format ("%x, %X");
      post_info_label.label   = _("%s using %s").printf (date_text, main_post.source);
      post_info_label.visible = true;
    } else {
      // Add relative date and link to page in corner
      string post_time_text = DisplayUtils.display_time_delta (main_post.creation_date);
      post_time_label.label = @"<a href=\"$(main_post.url)\" title=\"$(open_link_label)\" class=\"weblink\">$(post_time_text)</a>";
    }

    // Display post message in main label
    post_text_label.label      = main_post.text;
    post_text_label.selectable = display_type == MAIN;

    // Display media if post contains some
    if (main_post.get_media ().length > 0) {
      media_previewer.display_media (main_post.get_media ());
      media_previewer.visible = true;
    }

    // Display quote if not itself quote display
    if (main_post.post_type == QUOTE && display_type != QUOTE) {
      var quote_post = new PostDisplay (main_post.referenced_post, QUOTE);
      quote_container.append (quote_post);
      quote_container.visible = true;
    }

    // Make the UI smaller in a quote display
    if (display_type == QUOTE) {
      post_text_label.set_css_classes ({ "caption" });
      post_time_label.set_css_classes ({ "caption" });
      author_display_label.set_css_classes ({ "caption-heading" });
      author_avatar.size      = 32;
      author_badges.icon_size =  8;
    }

    // Set up either metrics or action box
    if (display_type == MAIN) {
      // Set up action box
      post_actions_box.visible = true;

      // Set up metrics in buttons
      post_like_button_display.label   = main_post.liked_count.to_string ("%'d");
      post_repost_button_display.label = main_post.reposted_count.to_string ("%'d");
      if (main_post.replied_count >= 0) {
        post_reply_button_display.label  = main_post.replied_count.to_string ("%'d");
      }

      // Set up options menu
      var    post_options_menu = new Menu ();
      post_options_menu.append (open_link_label, "post_display.open_link");
      post_options_button.menu_model = post_options_menu;
    } else {
      // Set up metrics box
      post_metrics_box.visible = true;

      // Set up metrics labels
      post_likes_display_label.label   = main_post.liked_count.to_string ("%'d");
      post_reposts_display_label.label = main_post.reposted_count.to_string ("%'d");
      if (main_post.replied_count >= 0) {
        post_replies_display_label.label = main_post.replied_count.to_string ("%'d");
      } else {
        // Hide the replies metric if we don't get data for it.
        post_replies_display_box.visible = false;
      }
    }

    // Set up "Open link" action
    this.install_action ("post_display.open_link", null, (widget, action) => {
      // Get the instance for this
      PostDisplay display = (PostDisplay) widget;

      // Open link to main post
      Gtk.show_uri (null, display.main_post.url, Gdk.CURRENT_TIME);
    });

    // Set up "display media" action
    this.install_action ("post_display.display_media", "i", (widget, action, arg) => {
      // Get the instance for this
      PostDisplay display = (PostDisplay) widget;

      // Get the parameters
      int             focus = (int) arg.get_int32 ();
      Backend.Media[] media = display.main_post.get_media ();

      // Get the MainWindow for this PostDisplay
      Gtk.Root display_root = display.get_root ();
      if (display_root is MainWindow) {
        var main_window = (MainWindow) display_root;
        main_window.show_media_display (media, focus);
      } else {
        error ("PostDisplay: Can not display MediaDisplay without MainWindow!");
      }
    });
  }

  /**
   * The displayed post.
   */
  private Backend.Post displayed_post;

  /**
   * The post displayed in the main view.
   */
  private Backend.Post main_post;

}
