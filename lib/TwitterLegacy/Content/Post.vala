/* Post.vala
 *
 * Copyright 2021-2022 Frederick Schenk
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
public class Backend.TwitterLegacy.Post : Backend.Post {

  /**
   * Parses an given Json.Object and creates an Post object.
   *
   * @param json A Json.Object retrieved from the API.
   */
  public Post.from_json (Json.Object json) {
    // Parse source name
    string application  = json.get_string_member ("source");
    try {
      var    source_regex = new Regex ("<a.*?>(.*?)</a>");
      application = source_regex.replace (
        application,
        application.length,
        0,
        "\\1"
      );
    } catch (RegexError e) {
      error (@"Error while parsing source: $(e.message)");
    }

    // Parse the referenced post and post_type
    Json.Object? referenced_obj = null;
    PostType     set_post_type  = NORMAL;

    // If this is a quote or repost, create a referenced post
    if (json.has_member ("quoted_status")) {
      referenced_obj = json.get_object_member ("quoted_status");
      set_post_type  = QUOTE;
    } else if (json.has_member ("retweeted_status")) {
      referenced_obj = json.get_object_member ("retweeted_status");
      set_post_type  = REPOST;
    }

    // Get strings used to compose the url.
    var    post_author = new User.from_json (json.get_object_member ("user"));
    string author_name = post_author != null ? post_author.username : "";
    string post_id     = json.get_string_member ("id_str");

    // Construct object with properties
    Object (
      // Set basic data
      id:            post_id,
      creation_date: Utils.TextUtils.parse_time (json.get_string_member ("created_at")),
      post_type:     set_post_type,
      source:        application,

      // Set url and domain
      domain: "Twitter.com",
      url:    @"https://twitter.com/$(author_name)/status/$(post_id)",

      // Set metrics
      liked_count:    (int) json.get_int_member ("favorite_count"),
      reposted_count: (int) json.get_int_member ("retweet_count"),
      replied_count:  -1, // Set to -1 as no data from API

      // Set referenced objects
      author:          post_author,
      referenced_post: referenced_obj != null ? new Post.from_json (referenced_obj) : null
    );

    // Parse the text into modules
    Json.Object? entities   = null;
    string       raw_text   = "";
    uint         text_start = 0;

    if (json.has_member ("display_text_range")) {
      Json.Array text_range = json.get_array_member ("display_text_range");
      text_start = (uint) text_range.get_int_element (0);
    }
    if (json.has_member ("full_text")) {
      raw_text = json.get_string_member ("full_text") [text_start:];
    } else {
      raw_text = json.get_string_member ("text") [text_start:];
    }
    if (json.has_member ("entities")) {
      entities = json.get_object_member ("entities");
    }

    text_modules = Utils.TextUtils.parse_text (raw_text, entities);

    // First format of the text.
    text = Backend.Utils.TextUtils.format_text (text_modules);

    // Check if a media array is present
    Json.Array media_array = null;
    if (json.has_member ("extended_entities")) {
      Json.Object ext_entities = json.get_object_member ("extended_entities");
      media_array = ext_entities.get_array_member ("media");
    } else if (entities.has_member ("media")) {
      media_array = entities.get_array_member ("media");
    }

    // Parse attached media from array
    Backend.Media[] parsed_media = {};
    if (media_array != null) {
      media_array.foreach_element ((array, index, element) => {
        if (element.get_node_type () == OBJECT) {
          Json.Object obj    = element.get_object ();
          parsed_media += new Backend.TwitterLegacy.Media.from_json (obj);}
      });
    }
    attached_media = parsed_media;
  }

}
