# Node.js client for adbot.io

Adbot.io is advertising platform for telegram bots.

### Install
```
$ npm install adbot
```

## API
```
var adbot = require('adbot')('ADBOT_API_KEY', BOT_ID);
```

### Usage
#### Pushing event
```
var adbot = require('adbot')(ADBOT_API_KEY, BOT_ID);

// ...
// Pushing event in some moment
//
var params = {
  // the event must be registered at http://adbot.io
  event: 'somePrettyEventName',

  // optional, default is false. Show test message to user
  test: true,

  // seet "chat" field from https://core.telegram.org/bots/api#message
  chat: {
    id: 123456,
    type: 'private'
  },

  // see "user" field from https://core.telegram.org/bots/api#message
  user: {
    id: 123456,
    username: 'john_doe',
    firstName: 'John',
    lastName: 'Doe'
  },

  // optional
  reply_to_message_id: 2345678,

  // optional, should be JSON or JSON-serialized object
  // see:
  // https://core.telegram.org/bots/api#replykeyboardmarkup
  // https://core.telegram.org/bots/api#replykeyboardhide
  // https://core.telegram.org/bots/api#forcereply
  reply_markup: {}
};
adbot.emitEvent(params, function (err, res) {
  if (res.shown) {
    console.log('Advert shown to user')
  }
  else {
    console.log('Advert not shown to user.')
    if (res.error) {
      console.error(res.error);
    }
  }
});
```

#### Sync bot (partner API)
```
var adbot = require('adbot')(ADBOT_API_KEY, BOT_ID);

// Some route, which handles sync
app.post('/my_sync_handler', function (req, res) {
  adbot.partnerSync(req.body, function (callback) {
    // Your should return a promise or invoke the callback with follow data:
    // If action is 'enable' then a list of events with descriptions
    // Otherwise if action is 'disable' then {success: true}
    // In both cases your should provide a telegram API key of the bot to calculate the digest.
    // API key will not be transfer to adbot.io
    // ...
    // Your code here.
    getBotDataInSomeWay(function (err, bot) {
      if (err) {
        return callback(err);
      }
      var data = {key: bot.key};
      // Enable bot in some way
      if (req.body.action === 'enable') {
        data.events = [
          {name: 'event1', description: 'some description'},
          {name: 'event2', description: 'some description'}
        ]
        callback(null, data)
      }
      // Disable bot in some way
      else {
        bot.disableBotInSomeWay(function (err) {
          if (err) {
            return callback(err)
          }
          data.success = true;
          callback(null, data)
        });
      }
    });
  });
});
```