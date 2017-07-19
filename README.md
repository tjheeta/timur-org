# Ttl

## What

- Capture
- Schedule the time to do it.

- Goals / things / tasks that want to accomplish
- Countdown the number of days to accomplish 
- Get reminded
- Encouragement from others who have the same goal
- Reminder / categorization - groceries, etc based on location
  - Notifications 
    - https://github.com/realtime-framework/WebPushNotifications/blob/master/index.js
    - https://pushcrew.com/pricing/
    - https://gauntface.github.io/simple-push-demo/
    - https://github.com/GoogleChrome/samples/tree/gh-pages/push-messaging-and-notifications
    - https://github.com/web-push-libs/web-push-php
    - https://elixirforum.com/t/what-is-the-simplest-way-to-send-notification-from-elixir-app-to-android-device/6264/4

Object/Item/Task (this is the fundamental unit - could be part of goal or habit)
  - UserId
  - ObjectId
  - GoalId maybe null
  - HabitId maybe null
  - ReferenceId (jira, email, picture, note, outlook, integrations, comments)
  - Properties (likable, commentable, private, etc)
  - Path - in case there are many subtasks
  - Blob
  - Minimum time needed
  - Time spent
  - Time left
  - State
  - Times deferred

Goals
  - Habit (streak based)
  - Time limit
    - Weekly
    - 40 days (short)
    - 6 months (medium)
    - 1 year (long)
  - Success criteria?
  - Could be suggested
  - Breakdown Items + Time
  - Weekly review
  - Reward
  - Start Date
  - End Date

Interaction
  - Comments
  - Reaction (time, parent, author)

Prioritizer
  - bin-packing based on min-time, deadline, priority
  - Every x-y days
  - Schedule
  - Deadline
  - Priority
  - Prior scheduling that worked and was successful
  - Saves the event and the suggestion

Groups
  - set of users
  - topics
  - interactions

Interaction
  - ObjectId
  - UserId
  - Comments
  - Reaction (time, parent, author)

Journal
  - day
  - rating
  - frequency

Open Times
  - UserId
  - Calendar
  - Scheduling
  - Tags associated with times
  - Enum(Tagged - will schedule with tag, Open)

  - Calendar implementation:
    - user_id + template
    - template:
      - { day, date, time, type={"base", "override"}, tag={"work", "sleep", etc} }
      - {[1-5], nil, [9-17], "base", "work"}
      - {[1-5], nil, [8-830], "base", "commute"}
      - {[1-5], nil, [1630-1730], "base", "commute"}
      - {nil, 2017-07-04, nil, type="override", tag={"offday"}


Tags
  - project (assoc with work)
  - podcast (assoc with any)
  - gardening (assoc with home)
  - woodworking (assoc with home)
  - health (assoc with any)
  - meditation (assoc with home)
  - reading (assoc with any)
  - writing (assoc with any)
  - hiking (assoc with offday)

Context
  - bus
  - home
  - work
  - in transport
  - offday

State:
  - stuck
  - delay
  - 5min
  - done
  - open
  - started


Mix:
mix phx.gen.html Accounts User users email:string access_token:string

mix phx.gen.html Things Object objects user_id:references:accounts_users path:array:uuid text:text blob:binary min_time_needed:integer time_spent:integer time_left:integer state:string defer_count:integer is_public:integer

mix phx.gen.html Things Tag tags user_id:references:accounts_users tag:string

created many to many table objects_tags


