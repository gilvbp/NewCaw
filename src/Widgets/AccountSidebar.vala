/* AccountSidebar.vala
 *
 * Copyright 2022 Frederick Schenk
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
 * Allows to change an account and displays related views for MainPage.
 */
[GtkTemplate (ui="/uk/co/ibboard/Cawbird/ui/Widgets/AccountSidebar.ui")]
public class AccountSidebar : Gtk.Widget {

  // UI-Elements of AccountSidebar
  [GtkChild]
  private unowned Gtk.ListBox active_list;
  [GtkChild]
  private unowned Gtk.ListBox account_list;

  /**
   * The currently active account.
   */
  public Backend.Account active_account { get; set; }

  /**
   * Run at construction of an widget.
   */
  construct {
    account_list.bind_model (Session.instance.account_list, bind_account);
  }

  /**
   * Changes the accounts when one was selected in the sidebar.
   *
   * @param widget The widget that was clicked in the account list.
   */
  [GtkCallback]
  private void change_active_account (Gtk.ListBoxRow widget) {
    // Get the AccountRow
    var account_row = widget as AccountRow;
    if (account_row == null) {
      warning ("Activated row is not AccountRow!");
      return;
    }

    // Get the MainWindow
    var main_window = this.get_root () as MainWindow;
    if (main_window == null) {
      warning ("AccountSidebar not in a MainWindow, action not possible!");
      return;
    }

    // Set the new account
    if (account_row.account != null) {
      main_window.account = account_row.account;
    }
  }

  /**
   * Binds an account to an AccountRow in the accounts list.
   */
  private Gtk.Widget bind_account (Object item) {
    var account    = item as Backend.Account;
    var widget     = new AccountRow ();
    widget.account = account;
    return widget;
  }

  /**
   * Deconstructs AccountSidebar and it's childrens.
   */
  public override void dispose () {
    // Destructs children of AccountSidebar
    active_list.unparent ();
    account_list.unparent ();
    base.dispose ();
  }

}
