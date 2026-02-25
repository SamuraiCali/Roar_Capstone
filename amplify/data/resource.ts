import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

/*
 * Schema definition for Roar
 * - Post: Represents a social media post with video, tags, and timestamp.
 */

const schema = a.schema({
    User: a.model({
        username: a.string().required(),
        profilePicURL: a.string(),
        bio: a.string(),

        posts: a.hasMany('Post', 'authorId'),
        comments: a.hasMany('Comment', 'userId'),
        likesList: a.hasMany('Like', 'userId'),

        followers: a.hasMany('Follow', 'followingId'),
        following: a.hasMany('Follow', 'followerId')
    }).authorization(allow => [
        allow.publicApiKey().to(['read']),
        allow.owner()
    ]),

    Post: a.model({
        videoURL: a.string(),
        teamTag: a.string(),
        sportTag: a.string(),
        timestamp: a.datetime(),
        description: a.string().required(),
        likes: a.integer().default(0),

        authorId: a.id(),
        author: a.belongsTo('User', 'authorId'),

        comments: a.hasMany('Comment', 'postId'),
        likesList: a.hasMany('Like', 'postId')
    }).authorization(allow => [
        allow.publicApiKey().to(['read']),
        allow.owner()
    ]),

    Like: a.model({
        userId: a.id(),
        postId: a.id(),
        user: a.belongsTo('User', 'userId'),
        post: a.belongsTo('Post', 'postId')
    }).authorization(allow => [
        allow.publicApiKey().to(['read']),
        allow.owner()
    ]),

    Comment: a.model({
        content: a.string().required(),
        userId: a.id(),
        postId: a.id(),
        user: a.belongsTo('User', 'userId'),
        post: a.belongsTo('Post', 'postId')
    }).authorization(allow => [
        allow.publicApiKey().to(['read']),
        allow.owner()
    ]),

    Follow: a.model({
        followerId: a.id(),
        followingId: a.id(),
        follower: a.belongsTo('User', 'followerId'),
        following: a.belongsTo('User', 'followingId')
    }).authorization(allow => [
        allow.publicApiKey().to(['read']),
        allow.owner()
    ])
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
    schema,
    authorizationModes: {
        defaultAuthorizationMode: 'userPool',
        // API Key is used for public access
        apiKeyAuthorizationMode: {
            expiresInDays: 30,
        },
    },
});
