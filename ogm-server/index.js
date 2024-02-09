const { Neo4jGraphQL } = require("@neo4j/graphql");
const { ApolloServer } = require("apollo-server");
const neo4j = require("neo4j-driver");
const dotenv = require("dotenv");
dotenv.config();
const env = process.env;
const driver = neo4j.driver(
    env.NEO4J_URI,
    neo4j.auth.basic(env.NEO4J_USERNAME, env.NEO4J_PASSWORD)
);
const typeDefs = `#graphql
    type User @authorization(validate: [
        { where: {node: {id: "$jwt.sub"} } }
        { where: {jwt: {roles_INCLUDES: "admin", sub: "-1"} } }
    ]){
        id: ID! @id
        username: String!
        password: String! @selectable(onAggregate: false)
        email: String!
        profile: String
    }
    type JWT @jwt {
        roles: [String!]!
    }
`;

const neoSchema = new Neo4jGraphQL({ typeDefs, driver, features: {authorization: {
    key: "demo-jwt-key",
}} });
async function main() {
    const schema = await neoSchema.getSchema();
    const server = new ApolloServer({
        schema,
        context: async ({ req }) => {
            return ({ token: req.headers.authorization })
        },
    });
    await server.listen(3000);
    console.log("online now")
}

main()

