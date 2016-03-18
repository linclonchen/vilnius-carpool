class @NotificationService
  notifyRequestRide: (trip)->
    user = Meteor.user();
    requestor = getUserEmail(user);
    tripOwner = Meteor.users.findOne(trip.owner);
    emailText = 'User ' + requestor + ' wants to join the trip\n' + trip.fromStreet + ' ' + trip.fromHouse + '-' + trip.toStreet + ' ' + trip.toHouse + '\n'
    Email.send
      from: requestor || "spastai@gmail.com",
      to: getUserEmail(tripOwner),
      subject: "Asking to join the trip",
      text: emailText

  notify: (reason, userId, doc)->
    da ["trips-matcher"], "Notify #{userId}: #{text}"
    text = "Added trip: #{doc.fromAddress}-#{doc.toAddress}"
    last = NotificationHistory.findOne({}, sort: addedAt: -1)
    badge = 1
    if last != null
      badge = last?.badge + 1
    NotificationHistory.insert {
      badge: badge
      addedAt: new Date
      trip: doc._id
      userId: userId
      reason: reason
    }, (error, result) ->
      ###
      Push.send
        from: 'push'
        title: 'Carpool'
        text: text
        badge: badge
        payload:
          title: 'Hello World'
          historyId: result
        query: userId: userId
      ###