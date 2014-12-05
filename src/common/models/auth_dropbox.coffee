Promise = require 'bluebird'
Sequelize = require 'sequelize'

model = (sequelize) ->
    sequelize.define(
        "AuthDropbox",
        {
            providerId:
                type:Sequelize.INTEGER
                unique: true
                allowNull: false
            displayName:
                type: Sequelize.STRING(255)
                allowNull: false
            email:
                type: Sequelize.STRING(255)
                allowNull: false
            accessToken:
                type: Sequelize.STRING(255)
                allowNull: false
            rootDir:
                type: Sequelize.STRING(255)
            cursor:
                type: Sequelize.STRING(255)
        },
        {
            tableName:"auth_dropbox"
        }
    )

associations = (sequelize) ->
    AuthDropbox = sequelize.model 'AuthDropbox'
    User = sequelize.model 'User'

    User.hasOne AuthDropbox, as:"authDropbox"

findOrCreate = (sequelize, accessToken, profile) ->
    find(sequelize, profile.id)
        .then (user) -> user ? create(sequelize, accessToken, profile)

find = (sequelize, profileId) ->
    User = sequelize.model 'User'
    AuthDropbox = sequelize.model 'AuthDropbox'
    User.find(
       include: [
            {
                model: AuthDropbox,
                as:"authDropbox",
                required: true,
                where: ['"authDropbox"."providerId" = ?', profileId ]
            }
       ]
    )

create = (sequelize, accessToken, profile) ->
    User = sequelize.model 'User'
    AuthDropbox = sequelize.model 'AuthDropbox'
    sequelize.transaction (t) ->
        email = profile.emails?[0]?.value
        displayName = profile.displayName
        userPromise = User.create({
            primaryEmail:email,
            primaryDisplayName:displayName
        })
        authPromise = AuthDropbox.create({
            email:email
            displayName:displayName
            providerId:profile.id
            accessToken:accessToken
        })
        Promise
            .all([userPromise, authPromise])
            .spread (user, auth) ->
                user
                    .setAuthDropbox auth
                    .then(
                        -> t.commit()
                        -> t.rollback()
                    )
                    .then -> user


module.exports = { model, associations, findOrCreate, find, create }