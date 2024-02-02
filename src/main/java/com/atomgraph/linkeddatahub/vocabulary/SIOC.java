/**
 *  Copyright 2023 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.vocabulary;

import org.apache.jena.ontology.*;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;

/**
 * SIOC vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */

public class SIOC {
  /**
   * <p>
   * The ontology model that holds the vocabulary terms
   * </p>
   */
  private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);

  /**
   * <p>
   * The namespace of the vocabulary as a string
   * </p>
   */
  public static final String NS = "http://rdfs.org/sioc/ns#";

  /**
   * Default prefix for this namespace.
   */
  public static final String PREFIX = "sioc";

  /**
   * <p>
   * The namespace of the vocabulary as a string
   * </p>
   *
     * @return the URI of this namespace
   * @see #NS
   */
  public static String getURI() {
    return NS;
  }

  /**
   * <p>
   * The namespace of the vocabulary as a resource
   * </p>
   */
  public static final Resource NAMESPACE = m_model.createResource(NS);

  // Vocabulary properties
  // /////////////////////////

  /**
   * <p>
   * Specifies that this Item is about a particular resource, e.g. a Post describing a book, hotel,
   * etc.
   * </p>
   */
  public static final ObjectProperty ABOUT = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#about");

  /**
   * <p>
   * Refers to the foaf:Agent or foaf:Person who owns this sioc:User online account.
   * </p>
   */
  public static final ObjectProperty ACCOUNT_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#account_of");

  /**
   * <p>
   * A Site that the User is an administrator of.
   * </p>
   */
  public static final ObjectProperty ADMINISTRATOR_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#administrator_of");

  /**
   * <p>
   * The URI of a file attached to an Item.
   * </p>
   */
  public static final ObjectProperty ATTACHMENT = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#attachment");

  /**
   * <p>
   * An image or depiction used to represent this User.
   * </p>
   */
  public static final ObjectProperty AVATAR = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#avatar");

  /**
   * <p>
   * An Item that this Container contains.
   * </p>
   */
  public static final ObjectProperty CONTAINER_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#container_of");

  /**
   * <p>
   * A resource that the User is a creator of.
   * </p>
   */
  public static final ObjectProperty CREATOR_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#creator_of");

  /**
   * <p>
   * An electronic mail address of the User.
   * </p>
   */
  public static final ObjectProperty EMAIL = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#email");

  /**
   * <p>
   * A feed (e.g. RSS, Atom, etc.) pertaining to this resource (e.g. for a Forum, Site, User, etc.).
   * </p>
   */
  public static final ObjectProperty FEED = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#feed");

  /**
   * <p>
   * Indicates that one User follows another User (e.g. for microblog posts or other content item
   * updates).
   * </p>
   */
  public static final ObjectProperty FOLLOWS = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#follows");

  /**
   * <p>
   * A User who has this Role.
   * </p>
   */
  public static final ObjectProperty FUNCTION_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#function_of");

  /**
   * This property has been renamed. Use <samp>sioc:sioc:usergroup_of</samp> instead.
   */
  public static final ObjectProperty GROUP_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#group_of");

  /**
   * <p>
   * A User who is an administrator of this Site.
   * </p>
   */
  public static final ObjectProperty HAS_ADMINISTRATOR = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_administrator");

  /**
   * <p>
   * The Container to which this Item belongs.
   * </p>
   */
  public static final ObjectProperty HAS_CONTAINER = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_container");

  /**
   * <p>
   * This is the User who made this resource.
   * </p>
   */
  public static final ObjectProperty HAS_CREATOR = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_creator");

  /**
   * <p>
   * The discussion that is related to this Item.
   * </p>
   */
  public static final ObjectProperty HAS_DISCUSSION = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_discussion");

  /**
   * <p>
   * A Role that this User has.
   * </p>
   */
  public static final ObjectProperty HAS_FUNCTION = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_function");

  /**
   * This property has been renamed. Use <samp>sioc:has_usergroup</samp> instead.
   */
  public static final ObjectProperty HAS_GROUP = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_group");

  /**
   * <p>
   * The Site that hosts this Forum.
   * </p>
   */
  public static final ObjectProperty HAS_HOST = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_host");

  /**
   * <p>
   * A User who is a member of this Usergroup.
   * </p>
   */
  public static final ObjectProperty HAS_MEMBER = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_member");

  /**
   * <p>
   * A User who is a moderator of this Forum.
   * </p>
   */
  public static final ObjectProperty HAS_MODERATOR = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_moderator");

  /**
   * <p>
   * A User who modified this Item.
   * </p>
   */
  public static final ObjectProperty HAS_MODIFIER = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_modifier");

  /**
   * <p>
   * A User that this resource is owned by.
   * </p>
   */
  public static final ObjectProperty HAS_OWNER = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_owner");

  /**
   * <p>
   * A Container or Forum that this Container or Forum is a child of.
   * </p>
   */
  public static final ObjectProperty HAS_PARENT = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_parent");

  /**
   * <p>
   * An resource that is a part of this subject.
   * </p>
   */
  public static final ObjectProperty HAS_PART = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_part");

  /**
   * <p>
   * Points to an Item or Post that is a reply or response to this Item or Post.
   * </p>
   */
  public static final ObjectProperty HAS_REPLY = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_reply");

  /**
   * <p>
   * A resource that this Role applies to.
   * </p>
   */
  public static final ObjectProperty HAS_SCOPE = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_scope");

  /**
   * <p>
   * A data Space which this resource is a part of.
   * </p>
   */
  public static final ObjectProperty HAS_SPACE = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_space");

  /**
   * <p>
   * A User who is subscribed to this Container.
   * </p>
   */
  public static final ObjectProperty HAS_SUBSCRIBER = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_subscriber");

  /**
   * <p>
   * Points to a Usergroup that has certain access to this Space.
   * </p>
   */
  public static final ObjectProperty HAS_USERGROUP = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#has_usergroup");

  /**
   * <p>
   * A Forum that is hosted on this Site.
   * </p>
   */
  public static final ObjectProperty HOST_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#host_of");

  /**
   * <p>
   * Links to the latest revision of this Item or Post.
   * </p>
   */
  public static final ObjectProperty LATEST_VERSION = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#latest_version");

  /**
   * <p>
   * A URI of a document which contains this SIOC object.
   * </p>
   */
  public static final ObjectProperty LINK = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#link");

  /**
   * <p>
   * Links extracted from hyperlinks within a SIOC concept, e.g. Post or Site.
   * </p>
   */
  public static final ObjectProperty LINKS_TO = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#links_to");

  /**
   * <p>
   * A Usergroup that this User is a member of.
   * </p>
   */
  public static final ObjectProperty MEMBER_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#member_of");

  /**
   * <p>
   * A Forum that User is a moderator of.
   * </p>
   */
  public static final ObjectProperty MODERATOR_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#moderator_of");

  /**
   * <p>
   * An Item that this User has modified.
   * </p>
   */
  public static final ObjectProperty MODIFIER_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#modifier_of");

  /**
   * <p>
   * Next Item or Post in a given Container sorted by date.
   * </p>
   */
  public static final ObjectProperty NEXT_BY_DATE = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#next_by_date");

  /**
   * <p>
   * Links to the next revision of this Item or Post.
   * </p>
   */
  public static final ObjectProperty NEXT_VERSION = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#next_version");

  /**
   * <p>
   * A resource owned by a particular User, for example, a weblog or image gallery.
   * </p>
   */
  public static final ObjectProperty OWNER_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#owner_of");

  /**
   * <p>
   * A child Container or Forum that this Container or Forum is a parent of.
   * </p>
   */
  public static final ObjectProperty PARENT_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#parent_of");

  /**
   * <p>
   * A resource that the subject is a part of.
   * </p>
   */
  public static final ObjectProperty PART_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#part_of");

  /**
   * <p>
   * Previous Item or Post in a given Container sorted by date.
   * </p>
   */
  public static final ObjectProperty PREVIOUS_BY_DATE = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#previous_by_date");

  /**
   * <p>
   * Links to the previous revision of this Item or Post.
   * </p>
   */
  public static final ObjectProperty PREVIOUS_VERSION = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#previous_version");

  /**
   * <p>
   * Links either created explicitly or extracted implicitly on the HTML level from the Post.
   * </p>
   */
  public static final ObjectProperty REFERENCE = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#reference");

  /**
   * <p>
   * Related Posts for this Post, perhaps determined implicitly from topics or references.
   * </p>
   */
  public static final ObjectProperty RELATED_TO = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#related_to");

  /**
   * <p>
   * Links to an Item or Post which this Item or Post is a reply to.
   * </p>
   */
  public static final ObjectProperty REPLY_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#reply_of");

  /**
   * <p>
   * A Role that has a scope of this resource.
   * </p>
   */
  public static final ObjectProperty SCOPE_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#scope_of");

  /**
   * <p>
   * A resource which belongs to this data Space.
   * </p>
   */
  public static final ObjectProperty SPACE_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#space_of");

  /**
   * <p>
   * A Container that a User is subscribed to.
   * </p>
   */
  public static final ObjectProperty SUBSCRIBER_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#subscriber_of");

  /**
   * <p>
   * A topic of interest, linking to the appropriate URI, e.g. in the Open Directory Project or of a
   * SKOS category.
   * </p>
   */
  public static final ObjectProperty TOPIC = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#topic");

  /**
   * <p>
   * A Space that the Usergroup has access to.
   * </p>
   */
  public static final ObjectProperty USERGROUP_OF = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#usergroup_of");

  /**
   * <p>
   * The content of the Item in plain text format.
   * </p>
   */
  public static final DatatypeProperty CONTENT = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#content");

  /**
   * <p>
   * The encoded content of the Post, contained in CDATA areas.
   * </p>
   */
  public static final DatatypeProperty CONTENT_ENCODED = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#content_encoded");

  /**
   * <p>
   * When this was created, in ISO 8601 format.
   * </p>
   */
  public static final DatatypeProperty CREATED_AT = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#created_at");

  /**
   * <p>
   * The content of the Post.
   * </p>
   */
  public static final DatatypeProperty DESCRIPTION = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#description");

  /**
   * <p>
   * An electronic mail address of the User, encoded using SHA1.
   * </p>
   */
  public static final DatatypeProperty EMAIL_SHA1 = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#email_sha1");

  /**
   * <p>
   * First (real) name of this User. Synonyms include given name or christian name.
   * </p>
   */
  public static final DatatypeProperty FIRST_NAME = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#first_name");

  /**
   * <p>
   * An identifier of a SIOC concept instance. For example, a user ID. Must be unique for instances
   * of each type of SIOC concept within the same site.
   * </p>
   */
  public static final DatatypeProperty ID = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#id");

  /**
   * <p>
   * The IP address used when creating this Item. This can be associated with a creator. Some wiki
   * articles list the IP addresses for the creator or modifiers when the usernames are absent.
   * </p>
   */
  public static final DatatypeProperty IP_ADDRESS = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#ip_address");

  /**
   * <p>
   * Last (real) name of this user. Synonyms include surname or family name.
   * </p>
   */
  public static final DatatypeProperty LAST_NAME = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#last_name");

  /**
   * <p>
   * When this was modified, in ISO 8601 format.
   * </p>
   */
  public static final DatatypeProperty MODIFIED_AT = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#modified_at");

  /**
   * <p>
   * The name of a SIOC instance, e.g. a username for a User, group name for a Usergroup, etc.
   * </p>
   */
  public static final DatatypeProperty NAME = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#name");

  /**
   * <p>
   * A note associated with this resource, for example, if it has been edited by a User.
   * </p>
   */
  public static final DatatypeProperty NOTE = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#note");

  /**
   * <p>
   * The number of posts that this person has posted.
   * </p>
   */
  public static final ObjectProperty NUM_POSTS = m_model
      .createObjectProperty("http://rdfs.org/sioc/ns#num_posts");

  /**
   * <p>
   * The number of replies that this Item, Thread, Post, etc. has. Useful for when the reply
   * structure is absent.
   * </p>
   */
  public static final DatatypeProperty NUM_REPLIES = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#num_replies");

  /**
   * <p>
   * The number of times this Item, Thread, User profile, etc. has been viewed.
   * </p>
   */
  public static final DatatypeProperty NUM_VIEWS = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#num_views");

  /**
   * <p>
   * Keyword(s) describing subject of the Post.
   * </p>
   */
  public static final DatatypeProperty SUBJECT = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#subject");

  /**
   * <p>
   * This is the title (subject line) of the Post. Note that for a Post within a threaded discussion
   * that has no parents, it would detail the topic thread.
   * </p>
   */
  public static final DatatypeProperty TITLE = m_model
      .createDatatypeProperty("http://rdfs.org/sioc/ns#title");

  // Vocabulary classes
  // /////////////////////////

  /**
   * <p>
   * Community is a high-level concept that defines an online community and what it consists of.
   * </p>
   */
  public static final OntClass COMMUNITY = m_model.createClass("http://rdfs.org/sioc/ns#Community");

  /**
   * <p>
   * An area in which content Items are contained.
   * </p>
   */
  public static final OntClass CONTAINER = m_model.createClass("http://rdfs.org/sioc/ns#Container");

  /**
   * <p>
   * A discussion area on which Posts or entries are made.
   * </p>
   */
  public static final OntClass FORUM = m_model.createClass("http://rdfs.org/sioc/ns#Forum");

  /**
   * <p>
   * An Item is something which can be in a Container.
   * </p>
   */
  public static final OntClass ITEM = m_model.createClass("http://rdfs.org/sioc/ns#Item");

  /**
   * <p>
   * An article or message that can be posted to a Forum.
   * </p>
   */
  public static final OntClass POST = m_model.createClass("http://rdfs.org/sioc/ns#Post");

  /**
   * <p>
   * A Role is a function of a User within a scope of a particular Forum, Site, etc.
   * </p>
   */
  public static final OntClass ROLE = m_model.createClass("http://rdfs.org/sioc/ns#Role");

  /**
   * <p>
   * A Site can be the location of an online community or set of communities, with Users and
   * Usergroups creating Items in a set of Containers. It can be thought of as a web-accessible data
   * Space.
   * </p>
   */
  public static final OntClass SITE = m_model.createClass("http://rdfs.org/sioc/ns#Site");

  /**
   * <p>
   * A Space is a place where data resides, e.g. on a website, desktop, fileshare, etc.
   * </p>
   */
  public static final OntClass SPACE = m_model.createClass("http://rdfs.org/sioc/ns#Space");

  /**
   * <p>
   * A container for a series of threaded discussion Posts or Items.
   * </p>
   */
  public static final OntClass THREAD = m_model.createClass("http://rdfs.org/sioc/ns#Thread");

  /**
   * <p>
   * A User account in an online community site.
   * </p>
   */
  public static final OntClass USER_ACCOUNT = m_model.createClass("http://rdfs.org/sioc/ns#UserAccount");

  /**
   * <p>
   * A set of User accounts whose owners have a common purpose or interest. Can be used for access
   * control purposes.
   * </p>
   */
  public static final OntClass USERGROUP = m_model.createClass("http://rdfs.org/sioc/ns#Usergroup");

  // Vocabulary individuals
  // /////////////////////////

}