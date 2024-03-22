module gml.draw.texture;

import gml.sprite;

import bindbc.bgfx;

void init(){
	
}

void quit(){
	
}

TexturePageData[] textures;

struct TexturePageData{
	bgfx.TextureHandle handle;
}

alias Texture = TexturePageData*;

Texture spriteGetTexture(SpriteAsset spr, size_t subImg) nothrow @nogc{
	if(spr){
		if(subImg < spr.images.length){
			if(spr.images[subImg].textureID < textures.length){
				return &textures[spr.images[subImg].textureID];
			}
		}
	}
	return null;
}
alias sprite_get_texture = spriteGetTexture;
