/* Post.vala
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
 * Represents one posted status message.
 */
public class Backend.Mastodon.Post : Object, Backend.Post {

  /**
   * The unique identifier of this post.
   */
  public string id { get; }

  /**
   * The time this post was posted.
   */
  public DateTime date { get; }

  /**
   * The message of this post.
   */
  public string text { get; }

  /**
   * The source application who created this Post.
   */
  public string source { get; }

  /**
   * How often the post was liked.
   */
  public int64 liked_count { get; }

  /**
   * How often the post was replied to.
   */
  public int64 replied_count { get; }

  /**
   * How often this post was reposted or quoted.
   */
  public int64 reposted_count { get; }

  /**
   * Parses an given Json.Object and creates an Post object.
   *
   * @param json A Json.Object retrieved from the API.
   */
  public Post.from_json (Json.Object json) {
    // Get basic data
    _id   = json.get_string_member ("id");
    _date = new DateTime.from_iso8601 (
      json.get_string_member ("created_at"),
      new TimeZone.utc ()
    );
    Json.Object application = json.get_object_member ("application");
    _source = application.get_string_member ("name");

    // Get metrics
    _liked_count    = json.get_int_member ("favourites_count");
    _replied_count  = json.get_int_member ("replies_count");
    _reposted_count = json.get_int_member ("reblogs_count");

    // Parse the text into modules
    text_modules = TextUtils.parse_text (json.get_string_member ("content"));
    _text = Backend.TextUtils.format_text (text_modules);
  }

#if DEBUG
  /**
   * Returns the text modules.
   *
   * Only used in test cases and therefore only available in debug builds.
   */
  public TextModule[] get_text_modules () {
    return text_modules;
  }
#endif

  /**
   * The text split into modules for formatting.
   */
  private TextModule[] text_modules;

}
