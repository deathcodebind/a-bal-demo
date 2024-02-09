import ballerina/crypto;
import ballerina/graphql;
import ballerina/http;
import ballerina/io;
import ballerina/jwt;

listener http:Listener httpListener = new (4000);
listener graphql:Listener graphqlListener = new (httpListener);
configurable string gql_server_link = ?;
string QueryGetUserById = check io:fileReadString("queries/getUserById.graphql");
string QueryGetPasswordWithAccount = check io:fileReadString("queries/getPasswordWithAccount.graphql");
const MutationCreateNewUser = "mutation Mutation($input: [UserCreateInput!]!) {\ncreateUsers(input: $input) {\nusers {\nid\n}\n}\n}";

type User record {|
    int? id;
    string username;
    string email;
    string? password;
    string? profile;
|};

type UserCreateInput record {|
    string username;
    string email;
    string password;
    string? profile;
|};

service /graphql on graphqlListener {
    private graphql:Client gql_client;
    function init() returns error? {
        self.gql_client = check new (gql_server_link, {
            auth: {
                token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJyb2xlcyI6WyJhZG1pbiJdfQ.fw8otUsm0jn3G7dvWozix5p2QotN3AVyZNJAwY7n50E"
            }
        });
        
    }
    resource function get user(string id) returns User|error? {
        return check self.gql_client->execute(QueryGetUserById, {"id": id});
    }
    remote function newUser(UserCreateInput user) returns int|error? {
        return check self.gql_client->execute(MutationCreateNewUser, {"user": user});
    }
    resource function get signIn(string account, string password) returns string|error? {
        string[] password_hashed_from_server = check self.gql_client->execute(QueryGetPasswordWithAccount, {account});
        if password_hashed_from_server.length() == 0 {
            return error("account not found!");
        }
        byte[] password_hashed_from_user = crypto:hashSha256(password.toBytes());
        if password_hashed_from_user == password_hashed_from_server[0].toBytes() {
            return check jwt:issue({
                username: account,
                issuer: "server",
                audience: "should be a complicated string",
                expTime: 36000

            });
        } else {
            io:println(password_hashed_from_server);
            io:println(password_hashed_from_user);
            return error("password incorrect!");
        }
    }
}
