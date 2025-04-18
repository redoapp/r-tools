load("@rules_file//file:workspace.bzl", "files")

def file_repositories():
    files(
        name = "files",
        build = "//tools/file:files.bazel",
        ignores = [
            ".git",
            ".repos",
            "data",
            "node_modules",
            "redo/merchant-app/.nuxt",
            "redo/merchant-app/dist",
            "redo/merchant-app/node_modules",
            "redo/merchant-mobile",
            "redo/shopify-app/extensions/my-web-pixel/dist",
            "redo/shopify-app/extensions/my-web-pixel/src",
            "redo/shopify-app/extensions/redo-checkout-optimization-ui/dist",
            "redo/shopify-app/extensions/redo-checkout-optimization-ui/lib-dist",
            "redo/shopify-app/extensions/redo-checkout-optimization-ui/src",
            "redo/shopify-app/extensions/redo-checkout-ui/dist",
            "redo/shopify-app/extensions/redo-checkout-ui/lib-dist",
            "redo/shopify-app/extensions/redo-checkout-ui/src",
            "redo/shopify-app/extensions/redo-pos-ui/src",
            "redo/shopify-app/extensions/redo-pos-ui/dist",
            "redo/shopify-app/extensions/theme-extension/assets",
            "redo/shopify-app/extensions/redo-pos-ui/dist",
            "redo/shopify-app/extensions/redo-pos-ui/lib-dist",
            "redo/shopify-app/extensions/post-purchase-ui/dist",
            "redo/shopify-app/extensions/post-purchase-ui/src",
            "redo/shopify-app/node_modules",
            "redo/shop-mini/node_modules",
            "target",
            "tools/npm/.yarn",
        ],
        root_file = "//:WORKSPACE.bazel",
    )
