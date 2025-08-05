import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import javax.imageio.ImageIO;


public class BgRemover
{
    public static void main(String[] args)
        throws FileNotFoundException, IOException
    {
        BufferedImage brandBuffer = ImageIO.read(new FileInputStream("no-bg-brand0.png"));
        BufferedImage noBGBrandBuffer = new BufferedImage(brandBuffer.getWidth(), brandBuffer.getHeight(), BufferedImage.TYPE_INT_ARGB);
        Graphics brush = noBGBrandBuffer.createGraphics();

        Color blue = Color.decode(("#364D7D"));
        Color yellow = Color.decode(("#FCBF5A"));

        for(int x = 0; x < brandBuffer.getWidth(); x++)
        {
            for(int y = 0; y < brandBuffer.getHeight(); y++)
            {
                int color = brandBuffer.getRGB(x, y);
                
                if(color == yellow.getRGB())
                {
                    brush.setColor(yellow);
                    brush.fillRect(x, y, 1, 1);
                }
                else if(color == blue.getRGB())
                {
                    brush.setColor(Color.WHITE);
                    brush.fillRect(x, y, 1, 1);
                }
                
                // if(brush.getColor().getRGB() != Color.WHITE.getRGB())
                // if(brush.getColor().getRGB() != Color.BLACK.getRGB())
                // { brush.fillRect(x, y, 1, 1); }
            }
        }

        brush.dispose();
        
        // brandBuffer = noBGBrandBuffer;
        // noBGBrandBuffer = new BufferedImage(brandBuffer.getWidth(), brandBuffer.getHeight(), BufferedImage.TYPE_INT_ARGB);
        // Graphics2D brush2 = (Graphics2D)noBGBrandBuffer.createGraphics();
        // brush2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        // brush2.drawImage(brandBuffer, 0, 0, null);

        ImageIO.write(noBGBrandBuffer, "png", new FileOutputStream("no-bg-brand1.png"));
    }
}
