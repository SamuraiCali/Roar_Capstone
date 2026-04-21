import { defineAuth } from '@aws-amplify/backend';

/**
 * Define authentication resource
 * - Uses email as the login mechanism
 */
export const auth = defineAuth({
    loginWith: {
        email: true,
    },
});
