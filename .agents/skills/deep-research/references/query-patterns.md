# Query Patterns — Effective Search Strategies

## web/fetch URL Patterns

### Official Documentation

```
https://nextjs.org/docs/app/api-reference/[feature]
https://react.dev/reference/react/[hook-or-api]
https://tanstack.com/query/latest/docs/react/[topic]
https://www.prisma.io/docs/orm/[topic]
https://tailwindcss.com/docs/[utility]
https://zod.dev/?id=[topic]
```

### GitHub Search (via web/fetch)

```
# Issues with most reactions
https://github.com/[org]/[repo]/issues?q=is:issue+[keywords]+sort:reactions-+1-desc

# Discussions
https://github.com/[org]/[repo]/discussions?discussions_q=[keywords]

# Code search
https://github.com/search?q=[keywords]+language:typescript&type=code

# Recent releases / changelog
https://github.com/[org]/[repo]/releases
https://github.com/[org]/[repo]/blob/main/CHANGELOG.md
```

### Package Registries

```
# npm package info
https://www.npmjs.com/package/[package-name]

# Bundle size
https://bundlephobia.com/package/[package-name]@[version]

# npm trends comparison
https://npmtrends.com/[pkg1]-vs-[pkg2]-vs-[pkg3]
```

### Stack Overflow

```
https://stackoverflow.com/search?q=[keywords]+[tag:framework]&sort=votes
```

## grep_search Patterns (Codebase)

### Find existing patterns

```
# How is X used in this codebase?
grep: "import.*from.*[library]"
grep: "use[Hook]("
grep: "new [ClassName]"

# Find configuration
grep: "[FEATURE_FLAG]|[ENV_VAR]"
grep: "process.env.[VAR]"

# Find related tests
grep: "describe.*[feature]|test.*[feature]|it.*should.*[behavior]"
```

## Search Query Construction Rules

1. **Be specific**: `"TanStack Query v5" useInfiniteQuery pagination` > `react query pagination`
2. **Include version**: `next.js 16 app router caching` > `next.js caching`
3. **Use exact error**: `"TypeError: Cannot read properties of undefined"` + framework
4. **Alternate terms**: `server component|RSC|server-side` to cover terminology variants
5. **Exclude noise**: Add `-tutorial -beginner` for advanced topics
