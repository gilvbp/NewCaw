/* AccountsPage.vala
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
 * Displays the page regarding the appearance options.
 */
[GtkTemplate (ui="/uk/co/ibboard/Cawbird/ui/Preferences/AccountsPage.ui")]
public class Preferences.AccountsPage : Adw.PreferencesPage {

  // UI-Elements of AccountsPage
  [GtkChild]
  private unowned Gtk.ListBox account_list;

  /**
   * Run at construction of the page.
   */
  construct {
    account_list.bind_model (Session.instance.account_list, bind_account);
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

}
