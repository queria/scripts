import javax.swing.UIManager;
import javax.swing.UIManager.LookAndFeelInfo;

class ListLaF {
	/**
	 * Prints out listing of available Java LookAndFeels, current System a CrossPlatform ones.
	 *
	 * Usage:
	 * $ cd /tmp
	 * $ wget -q https://raw.github.com/queria/scripts/master/ListLaF.java
	 * $ javac ListLaF.java
	 * $ java ListLaF
	 * ... output follows
	 *
	 */

	public static void main(String[] args) {
		System.out.println("Listing available LaFs:");
		LookAndFeelInfo[] lafs = UIManager.getInstalledLookAndFeels();
		for(int sI=0; sI<lafs.length; sI++) {
			System.out.println("- " + lafs[sI].getClassName());
		}
		System.out.println("CrossPlatform one is: "+UIManager.getCrossPlatformLookAndFeelClassName());
		System.out.println("System one is: "+UIManager.getSystemLookAndFeelClassName());
		System.out.println("done");
	}

}
